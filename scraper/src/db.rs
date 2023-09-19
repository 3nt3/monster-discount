use sqlx::postgres::PgQueryResult;
use sqlx::{Pool, Postgres};

use crate::models::Store;

pub async fn save_scrape(
    discounted: bool,
    success: bool,
    price: Option<i32>,
    store_info: Option<String>,
    store: Store,
    pool: &Pool<Postgres>,
) -> Result<PgQueryResult, sqlx::Error> {
    sqlx::query!(
        "INSERT INTO scrapes (discounted, success, price, store, store_info) VALUES ($1, $2, $3, $4, $5)",
        discounted,
        success,
        price,
        store as Store,
        store_info,
    )
    .execute(pool)
    .await
}

pub async fn discounted_last_time(
    market_id: i32,
    store: Store,
    pool: &Pool<Postgres>,
) -> Result<bool, sqlx::Error> {
    sqlx::query!(
        "SELECT discounted FROM scrapes WHERE store_info = $1 AND store = $2 ORDER BY created_at DESC LIMIT 1",
        market_id.to_string(),
        store as Store
    )
    .fetch_one(pool)
    .await
    .map(|x| x.discounted)
}


pub async fn delete_token(
    token: &str,
    pool: &Pool<Postgres>,
) -> Result<PgQueryResult, sqlx::Error> {
    sqlx::query!("DELETE FROM rewe_token__market WHERE token = $1", token)
        .execute(pool)
        .await
}
