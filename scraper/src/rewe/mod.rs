pub mod api;
pub mod models;

/// Query all prices for each market
pub async fn query_all_prices(pool: &sqlx::PgPool) -> anyhow::Result<()> {
    let markets = sqlx::query_as::<_, models::Market>("SELECT * FROM markets")
        .fetch_all(pool)
        .await?;

    Ok(markets)
}
