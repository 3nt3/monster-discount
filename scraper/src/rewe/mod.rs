pub mod api;
pub mod models;

use anyhow::{anyhow, Context};
use futures::{future::join_all, Future};

/// Query all prices for each market
pub async fn query_all_discounts(pool: &sqlx::PgPool) -> anyhow::Result<()> {
    let market_ids: Vec<i32> = sqlx::query!("SELECT DISTINCT market_id FROM rewe_token__market")
        .fetch_all(pool)
        .await?
        .iter()
        .map(|r| r.market_id)
        .filter(|m| m.is_some())
        .flatten()
        .collect();

    struct MarketOffers {
        market_id: i32,
        response: anyhow::Result<models::Response>,
    }

    let tasks: Vec<_> = market_ids
        .iter()
        .map(|market_id| async {
            log::info!("Querying market {}", *market_id);
            MarketOffers {
                response: api::get_offers(*market_id)
                    .await
                    .map_err(|e| anyhow!(e))
                    .context("Failed to get offers"),
                market_id: *market_id,
            }
        })
        .collect();

    let market_offers = join_all(tasks).await;
    market_offers.iter().for_each(|mo| {
        log::info!("Market {} has categories: {:?} ", mo.market_id, mo.response.as_ref().unwrap().categories);
    });

    Ok(())
}
