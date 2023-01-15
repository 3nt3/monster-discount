use crate::trinkgut::models::Listing;
use scraper::{Html, Selector};

use std::fs;

pub async fn get_listings(market_name: String) -> anyhow::Result<Vec<Listing>> {
    let text = reqwest::get(format!("https://www.trinkgut.de/markt/{market_name}"))
        .await?
        .text()
        .await?;

    let document = Html::parse_document(&text);

    fs::write("/tmp/test.html", &text).unwrap();

    let market_link_selector = Selector::parse("a.market-link--set-default").unwrap();
    let market_link = document
        .select(&market_link_selector)
        .next()
        .unwrap()
        .value()
        .attr("href")
        .unwrap();

    let market_id = market_link.split("/").last().unwrap();
    get_listings_by_market_id(market_id.to_string()).await;

    Ok(vec![])
}

async fn get_listings_by_market_id(market_id: String) -> anyhow::Result<Vec<Listing>> {
    let client = reqwest::Client::new();
    let response = client
        .get("https://www.trinkgut.de/aktuelle-angebote/")
        .send()
        .await?;

    // dbg!(&text);
    //
    dbg!(&response);
    let text = response.text().await?;

    let document = Html::parse_document(&text);
    fs::write("/tmp/test.html", &text).unwrap();

    let product_selector = Selector::parse(".product--info").unwrap();

    let title_selector = Selector::parse(".product--title").unwrap();
    let price_selector = Selector::parse(".product--price").unwrap();

    for element in document.select(&product_selector) {
        let title = element.select(&title_selector).next().unwrap();
        let price = element.select(&price_selector).next().unwrap();
        println!("{}, {}", title.text().collect::<Vec<_>>().join("").replace("\n", ""), price.text().collect::<Vec<_>>().join("").replace("\n", ""));
    }

    Ok(vec![])
}
