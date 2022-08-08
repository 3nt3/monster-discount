use crate::aldi::models;

pub async fn get_current_price() -> Result<i32, reqwest::Error> {
    let http_client = reqwest::Client::new();
    let http_builder = http_client
        .get("https://webservice.aldi-nord.de/api/v1/articles/products/getraenke/sport-energy-drinks/1007893-0-0.json")
        .header("User-Agent", "Dart/2.16.2 (dart:io)");
    let resp = http_builder.send().await;
    if let Err(err) = resp {
        return Err(err);
    }

    resp.unwrap()
        .json::<models::ProductResponse>()
        .await
        .map(|response| (response.price.parse::<f32>().unwrap() * 100f32) as i32)
}
