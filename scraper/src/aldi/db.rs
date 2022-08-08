use sqlx::{Pool, Postgres};

pub async fn get_last_price(pool: &Pool<Postgres>) -> Result<Option<i32>, sqlx::Error> {
    let res = sqlx::query!(
        "SELECT price FROM scrapes WHERE store = 'aldi' ORDER BY created_at DESC LIMIT 1"
    )
    .fetch_optional(pool)
    .await;

    if let Err(why) = res {
        Err(why)
    } else {
        Ok(res.unwrap().map(|x| x.price).flatten())
    }
}
