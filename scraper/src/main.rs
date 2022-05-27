use std::collections::HashMap;

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
    let client = reqwest::Client::new();
    let resp = client
        .get("https://mobile-api.rewe.de/api/v3/all-offers?marketCode=1940156")
        .header("User-Agent", "Dart/2.16.2 (dart:io)")
        .send()
        .await
        .unwrap();
    println!("{:#?}", resp.json::<Response>().await);
}
