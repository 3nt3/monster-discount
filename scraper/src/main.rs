use firebae_cm::{Client, Message, MessageBody, Notification, Receiver};
use gcp_auth::{AuthenticationManager, CustomServiceAccount};
use sqlx::postgres::{PgPoolOptions, PgQueryResult};
use sqlx::{Executor, Pool, Postgres};
use std::collections::HashMap;
use std::path::PathBuf;
use std::process::exit;
use std::str::FromStr;
use std::{env, thread};

use serde::Deserialize;

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Response {
    categories: Vec<Category>,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Category {
    title: String,
    offers: Vec<Offer>,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Offer {
    title: String,
    subtitle: String,
    price_data: PriceData,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct PriceData {
    price: Option<String>,
    regular_price: Option<String>,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct MarketInfo {
    id: String,
    name: String,
    address: Address,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Address {
    street: String,
    postal_code: String,
    city: String,
}

struct Scrape {
    id: i32,
    discounted: bool,
    created_at: chrono::DateTime<chrono::Utc>,
    success: bool,
    price: i32,
}

#[tokio::main]
async fn main() {
    dotenv::dotenv().unwrap();

    let database_url = env::var("DATABASE_URL").unwrap();

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .unwrap();

    let mut markets: HashMap<i32, Vec<String>> = HashMap::new();
    let db_data = sqlx::query!("SELECT token, market_id FROM token__market")
        .fetch_all(&pool)
        .await
        .unwrap();

    for item in &db_data {
        if let None = markets.get(&item.market_id) {
            markets.insert(item.market_id, vec![(&item.token).to_string()]);
        } else {
            markets
                .get_mut(&item.market_id)
                .unwrap()
                .push((&item.token).to_string());
        }
    }

    // authentication for google things
    let credentials_path = PathBuf::from(env::var("SERVICE_ACCOUNT").unwrap());
    let service_account = CustomServiceAccount::from_file(credentials_path).unwrap();
    let authentication_manager = AuthenticationManager::from(service_account);
    let scopes = &["https://www.googleapis.com/auth/firebase.messaging"];
    let oauth_token = authentication_manager.get_token(scopes).await.unwrap();

    for (market_id, tokens) in markets.into_iter() {
        let rewe_data_res = get_offers(market_id).await;
        if let Err(err) = &rewe_data_res {
            save_scrape(false, false, None, market_id, &pool).await;
            eprintln!("{}", err);
            continue;
        }

        let mut is_discounted = false;
        let mut price: Option<i32> = None;
        'catloop: for cat in rewe_data_res.unwrap().categories {
            for offer in cat.offers {
                if offer.title.to_lowercase().contains("monster") {
                    is_discounted = true;
                    let price_parsed_opt: Option<f32> =
                        offer.price_data.price.and_then(|x| x.parse::<f32>().ok());
                    price = price_parsed_opt.map(|x: f32| ((x * 100.0).round() as i32));

                    break 'catloop;
                }
            }
        }

        let market_info = get_market_info(market_id).await.unwrap();

        if discounted_last_time(market_id, &pool).await.ok() == Some(is_discounted) {
            println!(
                "already notified people about {} hopefully ({})",
                market_id, is_discounted
            );
            save_scrape(is_discounted, true, price, market_id, &pool).await;
            continue;
        }

        save_scrape(is_discounted, true, price, market_id, &pool).await;

        for token in tokens {
            let title: String;
            if !is_discounted {
                title = "Monster is not discounted anymore 😔".to_string();
            } else {
                if let Some(some_price) = &price {
                    title = format!(
                        "MONSTER IS DISCOUNTED TO {}€!! 🎉🎉",
                        (*some_price as f32) / 100.0
                    );
                } else {
                    title = "MONSTER IS DISCOUNTED 🎉".to_string();
                }
            }

            let notification = Notification {
                title: Some(title),
                body: Some(format!(
                    "At REWE {} in {}",
                    market_info.address.street, market_info.address.city
                )),
                image: Some("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Flogos-download.com%2Fwp-content%2Fuploads%2F2016%2F09%2FRewe_logo_Dein_Markt.png&f=1&nofb=1".to_string()), // EXTREMELY professional
            };

            let receiver = Receiver::Token(token.to_string());
            let mut body = MessageBody::new(receiver);
            body.notification(notification);

            let message = Message::new("monster-discount", oauth_token.as_str(), body);

            let client = Client::new();
            if let Err(err) = client.send(message).await {
                // if the device token is invalid because the app was uninstalled (hopefully that's
                // what it means at least), delete the token relationship to not do useless
                // requests
                //
                // TODO: concurrent requests to firebase - this will *not* scale well when all
                // notifications are sent one after another
                if err.to_string().starts_with("NOT_FOUND") {
                    let result = delete_token(&token, &pool).await;
                    if let Err(err) = result {
                        eprintln!("error deleting token from database: {}", err);
                    }
                    continue;
                }
                eprintln!("error sending push notification: {}", err);
            } else {
                println!(
                    "sent notification about '{} {}' to {}",
                    market_info.address.street, market_info.address.city, &token
                );
            }
        }

        // dbg!(resp.status());
    }
}

async fn get_market_info(market_id: i32) -> Option<MarketInfo> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        .get(format!(
            "https://mobile-api.rewe.de/mobile/markets/markets/{}",
            market_id
        ))
        .header("User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await.unwrap();

    Some(resp.json::<MarketInfo>().await.unwrap())
}

async fn get_offers(market_id: i32) -> Result<Response, reqwest::Error> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        // .get("https://mobile-api.rewe.de/api/v3/all-offers")
        .get("https://app.scrapingbee.com/api/v1")
        .query(&[
            ("api_key", env::var("SCRAPINGBEE_API_KEY").unwrap()),
            (
                "url",
                format!(
                    "https://mobile-api.rewe.de/api/v3/all-offers?marketCode={}",
                    market_id.to_string()
                ),
            ),
            ("render_js", "false".to_string()),
            ("forward_headers", "true".to_string()),
        ])
        .header("Spb-User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await;
    if let Err(err) = resp {
        return Err(err);
    }
    resp.unwrap().json::<Response>().await
}

async fn save_scrape(
    discounted: bool,
    success: bool,
    price: Option<i32>,
    market_id: i32,
    pool: &Pool<Postgres>,
) {
    sqlx::query!(
        "INSERT INTO scrapes (discounted, success, price, market_id) VALUES ($1, $2, $3, $4)",
        discounted,
        success,
        price,
        market_id
    )
    .execute(pool)
    .await;
}

async fn discounted_last_time(market_id: i32, pool: &Pool<Postgres>) -> Result<bool, sqlx::Error> {
    sqlx::query!(
        "SELECT discounted FROM scrapes WHERE market_id = $1 ORDER BY created_at DESC LIMIT 1",
        market_id
    )
    .fetch_one(pool)
    .await
    .map(|x| x.discounted)
}

async fn delete_token(token: &str, pool: &Pool<Postgres>) -> Result<PgQueryResult, sqlx::Error> {
    sqlx::query!("DELETE FROM token__market WHERE token = $1", token)
        .execute(pool)
        .await
}
