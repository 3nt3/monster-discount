use sqlx::{Pool, Postgres};

pub fn get_last_price(pool: &Pool<Postgres>) -> Result<i32, sqlx::Error> {
    let res = sqlx::query!(
        "SELECT price FROM scrapes WHERE store = 'aldi' ORDER BY created_at DESC LIMIT 1"
    )
    .fetch_optional(pool)
    .await
    .flatten()
    .map(|record| {record.map(|x| x.price)})
}
