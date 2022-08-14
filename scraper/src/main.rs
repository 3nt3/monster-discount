use firebae_cm::{Client, Message, MessageBody, Notification, Receiver};
use gcp_auth::{AuthenticationManager, CustomServiceAccount};
use std::collections::HashMap;
use std::env;
use std::path::PathBuf;

use sqlx::postgres::PgPoolOptions;

mod aldi;
mod db;
mod models;
mod rewe;

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
    let db_data =
        sqlx::query!("SELECT token, market_id FROM token__market WHERE market_id is not null")
            .fetch_all(&pool)
            .await
            .unwrap();

    for item in &db_data {
        if let Some(market_id) = item.market_id {
            if let None = markets.get(&market_id) {
                markets.insert(market_id, vec![(&item.token).to_string()]);
            } else {
                markets
                    .get_mut(&market_id)
                    .unwrap()
                    .push((&item.token).to_string());
            }
        }
    }

    // authentication for google things
    let credentials_path = PathBuf::from(env::var("SERVICE_ACCOUNT").unwrap());
    let service_account = CustomServiceAccount::from_file(credentials_path).unwrap();
    let authentication_manager = AuthenticationManager::from(service_account);
    let scopes = &["https://www.googleapis.com/auth/firebase.messaging"];
    let oauth_token = authentication_manager.get_token(scopes).await.unwrap();

    // rewe things
    for (market_id, tokens) in markets.into_iter() {
        let rewe_data_res = rewe::api::get_offers(market_id).await;
        if let Err(err) = &rewe_data_res {
            db::save_scrape(
                false,
                false,
                None,
                Some(market_id.to_string()),
                models::Store::Rewe,
                &pool,
            )
            .await
            .ok();
            eprintln!("{}", err);
            continue;
        }

        let product = rewe::api::get_current_price().await;
        let mut price: Option<i32> = product
            .map(|x| x.product.raw_values.current_retail_price)
            .ok();

        // this is redundant
        let mut is_discounted = false;
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

        let market_info = rewe::api::get_market_info(market_id).await.unwrap();

        if db::discounted_last_time(market_id, &pool).await.ok() == Some(is_discounted) {
            println!(
                "already notified people about {} hopefully ({}€, discounted: {})",
                market_id,
                price.map(|x| (x as f32) / 100.).unwrap_or(0.),
                is_discounted
            );
            db::save_scrape(
                is_discounted,
                true,
                price,
                Some(market_id.to_string()),
                models::Store::Rewe,
                &pool,
            )
            .await
            .ok();
            continue;
        }

        db::save_scrape(
            is_discounted,
            true,
            price,
            Some(market_id.to_string()),
            models::Store::Rewe,
            &pool,
        )
        .await
        .ok();

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
                    let result = db::delete_token(&token, &pool).await;
                    if let Err(err) = result {
                        eprintln!("error deleting token from database: {:?}", err);
                    }
                    continue;
                }
                eprintln!("error sending push notification: {:?}", err);
            } else {
                println!(
                    "sent notification about '{} {}' to {}",
                    market_info.address.street, market_info.address.city, &token
                );
            }
        }
    }

    // aldi things
    let last_aldi_price = aldi::db::get_last_price(&pool).await.unwrap();

    let aldi_price_res = aldi::api::get_current_price().await;
    if let Err(ref why) = aldi_price_res {
        eprintln!("error querying aldi: {why}");
        db::save_scrape(false, false, None, None, models::Store::AldiNord, &pool)
            .await
            .unwrap();
    }

    let aldi_price = aldi_price_res.unwrap();
    db::save_scrape(
        last_aldi_price.unwrap_or(0) > aldi_price,
        true,
        Some(aldi_price),
        None,
        models::Store::AldiNord,
        &pool,
    )
    .await
    .unwrap();

    println!(
        "aldi price: {aldi_price}, last price: {:?}",
        last_aldi_price
    );

    if last_aldi_price.is_none() || aldi_price >= last_aldi_price.unwrap_or(aldi_price) {
        println!("aldi isn't cheaper than last scrape");
    } else {
        let aldi_tokens = aldi::db::get_tokens(&pool).await.unwrap();

        for token in aldi_tokens {
            println!("aldi token: {token}");

            let notification = Notification {
                title: Some(format!(
                    "Monster is discounted to {}€ at ALDI Nord",
                    (aldi_price as f32) / 100.0
                )),
                body: Some("That's pretty cool ig".to_string()),
                image: None,
            };
            let receiver = Receiver::Token(token.to_string());
            let mut body = MessageBody::new(receiver);
            body.notification(notification);

            let message = Message::new("monster-discount", oauth_token.as_str(), body);

            let client = Client::new();
            match client.send(message).await {
                Err(why) => {
                    eprintln!("error happened: {why}");
                }
                Ok(what) => {
                    println!("{what}");
                }
            }
        }
    }
}
