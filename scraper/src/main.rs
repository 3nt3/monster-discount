#![feature(async_closure)]

use firebae_cm::{Client, Message, MessageBody, Notification, Receiver};
use gcp_auth::{AuthenticationManager, CustomServiceAccount};
use sqlx::{Pool, Postgres};
use std::collections::HashMap;
use std::env;
use std::path::PathBuf;

use futures::StreamExt;
use sqlx::postgres::PgPoolOptions;

#[macro_use]
extern crate log;

// mod aldi;
mod db;
mod models;
mod rewe;
mod trinkgut;

#[tokio::main]
async fn main() {
    // setup pretty_env_logger
    dotenv::dotenv().unwrap();
    pretty_env_logger::try_init().unwrap();

    let database_url = env::var("DATABASE_URL").unwrap();

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .unwrap();

    // authentication for google things
    let credentials_path = PathBuf::from(env::var("SERVICE_ACCOUNT").unwrap());
    let service_account = CustomServiceAccount::from_file(credentials_path).unwrap();
    let authentication_manager = AuthenticationManager::from(service_account);
    let scopes = &["https://www.googleapis.com/auth/firebase.messaging"];
    let oauth_token = authentication_manager.get_token(scopes).await.unwrap();

    // rewe
    let rewe_discounts = rewe::query_discounts_and_filter(&pool, "sekt").await;

}

// async fn trinkgut(pool: &Pool<Postgres>) -> anyhow::Result<()> {
//     // FIXME: don't hardcode one market
//     let market_id: String = trinkgut::scrape::get_market_id("elke-luck-ii".to_string()).await?;
//     let discounted =
//         trinkgut::scrape::is_product_discounted(&market_id, &"monster".to_string()).await?;
//     let price = if discounted { todo!() } else { None };

//     dbg!(
//         db::save_scrape(
//             discounted,
//             true,
//             price,
//             Some((&market_id).to_string()),
//             models::Store::TrinkGut,
//             &pool
//         )
//         .await?
//     );

//     let listings = trinkgut::scrape::get_listings_by_market_id(market_id).await?;

//     // write each one to db in parallel using stream::iter
//     let mut stream = futures::stream::iter(listings.iter())
//         .map(|listing| {
//             let pool = pool.clone();
//             async move { trinkgut::db::save_scrape(&pool, &listing).await }
//         })
//         .buffer_unordered(10);
//     stream
//         .for_each(|x| async {
//             if let Err(err) = x {
//                 eprintln!("error saving trinkgut scrape: {:?}", err);
//             }
//         })
//         .await;

//     Ok(())
// }
