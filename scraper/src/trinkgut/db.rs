use sqlx::{Pool, Postgres};

pub fn last_price(pool: &Pool<Postgres>, market_id: String) -> anyhow::Result<Option<i32>> {
    let res = sqlx::query!(
        "SELECT price FROM trinkgut_scrapes WHERE market_id = $1 ORDER BY created_at DESC LIMIT 1",
        market_id
    )
    .fetch_optional(pool)
    .await;

    if let Err(why) = res {
        Err(why)
    } else {
        Ok(res.unwrap().map(|x| x.price).flatten())
    }
}

