use serde::Deserialize;

pub struct Scrape {
    pub id: i32,
    pub discounted: bool,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub success: bool,
    pub price: i32,
}
