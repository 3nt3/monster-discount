use anyhow::Result;

pub async fn get_tokens_for_market_id(pool: &sqlx::PgPool, market_id: i32) -> Result<Vec<String>> {
    let tokens_and_market_ids: Vec<String> = sqlx::query!(
        "SELECT token FROM rewe_token__market WHERE market_id = $1",
        market_id
    )
    .fetch_all(pool)
    .await?
    .iter()
    .map(|r| r.token.clone())
    .collect();

    Ok(tokens_and_market_ids)
}
