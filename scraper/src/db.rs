use sqlx::postgres::PgQueryResult;
use sqlx::{Pool, Postgres};

pub async fn save_scrape(
    discounted: bool,
    success: bool,
    price: Option<i32>,
    market_id: i32,
    pool: &Pool<Postgres>,
) {
    sqlx::query!(
        "INSERT INTO scrapes (discounted, success, price, market_id) VALUES ($1, $2, $3, $4)",
        discounted,
        success,
        price,
        market_id
    )
    .execute(pool)
    .await;
}

pub async fn discounted_last_time(
    market_id: i32,
    pool: &Pool<Postgres>,
) -> Result<bool, sqlx::Error> {
    sqlx::query!(
        "SELECT discounted FROM scrapes WHERE market_id = $1 ORDER BY created_at DESC LIMIT 1",
        market_id
    )
    .fetch_one(pool)
    .await
    .map(|x| x.discounted)
}

pub async fn delete_token(
    token: &str,
    pool: &Pool<Postgres>,
) -> Result<PgQueryResult, sqlx::Error> {
    sqlx::query!("DELETE FROM token__market WHERE token = $1", token)
        .execute(pool)
        .await
}
