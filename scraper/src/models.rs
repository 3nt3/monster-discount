use serde::Deserialize;

pub struct Scrape {
    pub id: i32,
    pub discounted: bool,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub success: bool,
    pub price: i32,
    pub store: Store,
    pub store_info: String,
}

#[derive(sqlx::Type)]
#[sqlx(rename_all = "lowercase")]
#[derive(Debug)]
pub enum Store {
    Rewe,
    AldiNord,
    TrinkGut,
}

pub struct TokenAndMarketID {
    pub token: String,
    pub market_id: i32,
}
