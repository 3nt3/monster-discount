use firebae_cm::{Client, Message, MessageBody, Notification, Receiver};
use gcp_auth::{AuthenticationManager, CustomServiceAccount};
use sqlx::postgres::PgPoolOptions;
use sqlx::{Executor, Pool, Postgres};
use std::collections::HashMap;
use std::env;
use std::path::PathBuf;
use std::process::exit;

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

        for token in tokens {
            let notification = Notification {
                title: Some("Some title".to_string()),
                body: Some("Body".to_string()),
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
