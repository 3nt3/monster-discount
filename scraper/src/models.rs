use serde::Deserialize;

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Response {
    pub categories: Vec<Category>,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Category {
    pub title: String,
    pub offers: Vec<Offer>,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Offer {
    pub title: String,
    pub subtitle: String,
    pub price_data: PriceData,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct PriceData {
    pub price: Option<String>,
    pub regular_price: Option<String>,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct MarketInfo {
    pub id: String,
    pub name: String,
    pub address: Address,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Address {
    pub street: String,
    pub postal_code: String,
    pub city: String,
}

pub struct Scrape {
    pub id: i32,
    pub discounted: bool,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub success: bool,
    pub price: i32,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct MarketSearchResponse {
    pub items: Vec<MarketInfo>,
}
