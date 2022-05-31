use crate::models;
use std::env;

pub async fn get_market_info(market_id: i32) -> Option<models::MarketInfo> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        // .get(format!(
        //     "https://mobile-api.rewe.de/mobile/markets/markets/{}",
        //     market_id
        // ))
        .get("https://app.scrapingbee.com/api/v1")
        .query(&[
            ("api_key", env::var("SCRAPINGBEE_API_KEY").unwrap()),
            (
                "url",
                format!(
                    "https://mobile-api.rewe.de/mobile/markets/markets/{}",
                    market_id.to_string()
                ),
            ),
            ("render_js", "false".to_string()),
            ("forward_headers", "true".to_string()),
        ])
        .header("User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await.unwrap();

    Some(resp.json::<models::MarketInfo>().await.unwrap())
}

pub async fn get_offers(market_id: i32) -> Result<models::Response, reqwest::Error> {
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
    resp.unwrap().json::<models::Response>().await
}
