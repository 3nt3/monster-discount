use fcm::{Client, MessageBuilder};
use sqlx::postgres::PgPoolOptions;
use sqlx::{Executor, Pool, Postgres};
use std::collections::HashMap;
use std::env;

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
    dotenv::dotenv();
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
    for (market, tokens) in markets.iter() {
        let client = reqwest::Client::new();
        let builder = client
            .get("https://mobile-api.rewe.de/api/v3/all-offers")
            .query(&[("marketCode", market)])
            .header("User-Agent", "Dart/2.16.2 (dart:io)");
        dbg!(&builder);
        let resp = builder.send().await.unwrap();
        dbg!(resp.status());
    }
}
