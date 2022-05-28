use firebae_cm::{Client, Message, MessageBody, Notification, Receiver};
use gcp_auth::{AuthenticationManager, CustomServiceAccount};
use sqlx::postgres::PgPoolOptions;
use sqlx::{Executor, Pool, Postgres};
use std::collections::HashMap;
use std::env;
use std::path::PathBuf;
use std::process::exit;
use std::str::FromStr;

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

    for (market, tokens) in markets.iter() {
        let http_client = reqwest::Client::new();
        let http_builder = http_client
            .get("https://mobile-api.rewe.de/api/v3/all-offers")
            .query(&[("marketCode", market)])
            .header("User-Agent", "Dart/2.16.2 (dart:io)");
        let resp = http_builder.send().await.unwrap();
        let rewe_data = resp.json::<Response>().await.unwrap();

        let mut is_discounted = false;
        let mut price: Option<String> = None;
        'catloop: for cat in rewe_data.categories {
            for offer in cat.offers {
                if offer.title.to_lowercase().contains("monster") {
                    is_discounted = true;
                    price = offer.price_data.price;
                    break 'catloop;
                }
            }
        }

        if !is_discounted {
            break;
        }

        let market_info = get_market_info(*market).await.unwrap();

        for token in tokens {
            let title: String;
            if let Some(some_price) = &price {
                title = format!("MONSTER IS DISCOUNTED TO {}€!!", some_price);
            } else {
                title = "MONSTER IS DISCOUNTED".to_string();
            }

            let notification = Notification {
                title: Some(title),
                body: Some(format!(
                    "At REWE {} in {}",
                    market_info.address.street, market_info.address.city
                )),
                image: None,
            };

            let receiver = Receiver::Token(token.to_string());
            let mut body = MessageBody::new(receiver);
            body.notification(notification);

            let message = Message::new("monster-discount", oauth_token.as_str(), body);

            let client = Client::new();
            dbg!(client.send(message).await);
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
