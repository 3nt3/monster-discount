use crate::models::{self, ProductResponse};

pub async fn get_market_info(market_id: i32) -> Option<models::MarketInfo> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        .get(format!(
            "https://mobile-api.rewe.de/mobile/markets/markets/{}",
            market_id
        ))
        .header("User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await.unwrap();

    Some(resp.json::<models::MarketInfo>().await.unwrap())
}

pub async fn get_offers(market_id: i32) -> Result<models::Response, reqwest::Error> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        .get("https://mobile-api.rewe.de/api/v3/all-offers")
        .query(&[("marketCode", market_id)])
        .header("User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await;
    if let Err(err) = resp {
        return Err(err);
    }
    resp.unwrap().json::<models::Response>().await
}

pub async fn market_search(query: &str) -> Result<Vec<models::MarketInfo>, reqwest::Error> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        .get("https://mobile-api.rewe.de/api/v3/all-offers")
        .query(&[("query", query)])
        .header("User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await;
    if let Err(err) = resp {
        return Err(err);
    }
    resp.unwrap()
        .json::<models::MarketSearchResponse>()
        .await
        .map(|x| x.items)
}

pub async fn get_current_price() -> Result<ProductResponse, reqwest::Error> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        .get("https://mobile-api.rewe.de/mobile/products/13-5060337500401-f2bf8a20-3ff3-4fbc-9cea-984edf862b0f")
        .header("User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await;
    if let Err(err) = resp {
        return Err(err);
    }

    resp.unwrap().json::<models::ProductResponse>().await
}
