use sqlx::{Pool, Postgres};

use super::models::Listing;

pub async fn last_price(pool: &Pool<Postgres>, market_id: String) -> anyhow::Result<Option<i32>> {
    let res = sqlx::query!(
        "SELECT price FROM trinkgut_scrapes WHERE market_id = $1 ORDER BY created_at DESC LIMIT 1",
        market_id
    )
    .fetch_optional(pool)
    .await;

    match res {
        Err(why) => Err(why.into()),
        Ok(res) => match res {
            None => Ok(None),
            // format price as integer
            Some(res) => Ok(Some(res.price.parse::<i32>()?)),
        }
    }
}

pub async fn save_scrape(pool: &Pool<Postgres>, listing: &Listing) -> anyhow::Result<()> {
    let res = sqlx::query!("INSERT INTO trinkgut_scrapes (product_name, market_id, price, description, image_url) VALUES ($1, $2, $3, $4, $5)", listing.title, listing.market_id, listing.price, listing.description, listing.image_url).execute(pool).await?;
    Ok(())
}
