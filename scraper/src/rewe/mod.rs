pub mod api;
pub mod db;
pub mod models;

use anyhow::{anyhow, Context, Result};
use firebae_cm::{Client, Message, MessageBody, Notification, Receiver};
use futures::future::join_all;
use gcp_auth::Token;

use rand::seq::SliceRandom;

use crate::{
    db::discounted_last_time,
    models::Store,
    rewe::{api::get_market_info, models::Offer},
};

pub struct MarketOffers {
    market_id: i32,
    response: anyhow::Result<models::Response>,
}

/// Query all discounts for each market and filter for matching discounts
pub async fn query_discounts_and_filter(
    pool: &sqlx::PgPool,
    term: impl Into<String>,
) -> anyhow::Result<Vec<(i32, Offer)>> {
    let term: String = term.into();
    let everything = query_all_discounts(pool).await?;

    // Log all failed markets
    let failed_markets: Vec<_> = everything.iter().filter(|m| m.response.is_err()).collect();
    let market_infos = join_all(
        failed_markets
            .iter()
            .map(|m| async { get_market_info(m.market_id).await }),
    )
    .await;

    market_infos.iter().for_each(|m| {
        log::warn!("Scraping failed for market {:#?}", m);
    });

    let successful_markets = everything
        .iter()
        .filter(|m| m.response.is_ok())
        .collect::<Vec<_>>();

    // Filter for matching discounts

    // vec of (market_id, offer)
    let mut matching_discounts: Vec<(i32, Offer)> = Vec::new();

    for market_offers in successful_markets {
        for category in &market_offers.response.as_ref().unwrap().categories {
            for offer in &category.offers {
                if offer
                    .title
                    .to_lowercase()
                    .contains(term.to_lowercase().as_str())
                {
                    log::info!("Found matching discount: {:#?}", offer);
                    matching_discounts.push((market_offers.market_id, offer.clone()));
                }
            }
        }
    }

    Ok(matching_discounts)
}

/// Notifies users using firebase cloud messaging
pub async fn notify_fcm(
    pool: &sqlx::PgPool,
    discounts: Vec<(i32, Offer)>,
    oauth_token: Token,
) -> Result<()> {
    let emojis = ["🚀", "🌈", "💅", "🦀"];
    for (market_id, offer) in discounts {
        // check if we already notified about this discount
        let was_discounted = discounted_last_time(market_id, Store::Rewe, pool).await?;
        if was_discounted {
            log::info!(
                "Already notified about this {:?} at {}",
                offer.title,
                market_id
            );
            continue;
        }

        let tokens = db::get_tokens_for_market_id(pool, market_id)
            .await
            .context("Failed to get tokens for market_id")?;

        let discounted_price_string = offer.price_data.price.unwrap_or("discounted".to_string());

        // FIXME: cache this
        let market_info = get_market_info(market_id).await;
        let notification_title: String;
        let notification_body: String;

        let random_emoji = emojis.choose(&mut rand::thread_rng()).unwrap();

        if let Err(why) = market_info {
            log::warn!("Failed to get market info: {:#?}", why);

            notification_title = format!("Monster's {}€ {}", discounted_price_string, random_emoji);
            notification_body = format!("...somewhere (#{} ??)", market_id);
        } else {
            let market_info = market_info.unwrap();
            notification_title = format!("Monster's {}€ {}", random_emoji, discounted_price_string);
            notification_body = format!(
                "At {} in {}",
                market_info.address.street, market_info.address.city
            );
        }

        for token in tokens {
            let receiver = Receiver::Token(token.clone());
            let notification = Notification {
                title: Some(notification_title.clone()),
                body: Some(notification_body.clone()),
                image: None,
            };
            let mut body = MessageBody::new(receiver);
            body.notification(notification.clone());

            let message = Message::new("monster-discount", oauth_token.as_str(), body);

            let client = Client::new();
            let response = client.send(message).await;

            if let Err(why) = response {
                log::warn!("Failed to send notification: {:#?}", why);
            } else {
                log::debug!("Sent notification {:#?} to {}", notification.clone(), token);
            }
        }
    }

    todo!()
}

/// Query median price for a given market
async fn get_median_price(pool: &sqlx::PgPool, market_id: i32) -> anyhow::Result<Option<i32>> {
    // calculate median from db using percentile_disc
    let median = sqlx::query!(
        r#"
        SELECT percentile_disc(0.5) WITHIN GROUP (ORDER BY price) AS median
        FROM scrapes
        WHERE store_info = $1
        AND store = 'rewe'
        AND price IS NOT NULL
        "#,
        market_id.to_string()
    )
    .fetch_one(pool)
    .await?
    .median;

    Ok(median)
}

/// Query all prices for each market
pub async fn query_all_discounts(pool: &sqlx::PgPool) -> anyhow::Result<Vec<MarketOffers>> {
    let market_ids: Vec<i32> = sqlx::query!("SELECT DISTINCT market_id FROM rewe_token__market")
        .fetch_all(pool)
        .await?
        .iter()
        .map(|r| r.market_id)
        .filter(|m| m.is_some())
        .flatten()
        .collect();

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

    Ok(market_offers)
}
