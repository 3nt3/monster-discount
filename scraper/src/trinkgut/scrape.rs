use crate::trinkgut::models::Listing;
use scraper::{Html, Selector};

pub async fn get_listings(market_name: String) -> anyhow::Result<Vec<Listing>> {
    let text = reqwest::get(format!("https://www.trinkgut.de/markt/{market_name}"))
        .await?
        .text()
        .await?;

    let document = Html::parse_document(&text);

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

    let text = response.text().await?;

    let document = Html::parse_document(&text);

    let product_selector = Selector::parse(".product--info").unwrap();
    let title_selector = Selector::parse(".product--title").unwrap();
    let price_selector = Selector::parse(".product--price").unwrap();
    let image_selector = Selector::parse("img").unwrap();

    for element in document.select(&product_selector) {
        let maybe_title = element.select(&title_selector).next();
        let maybe_price = element.select(&price_selector).next();
        let maybe_image = element.select(&image_selector).next();

        match (maybe_title, maybe_price, maybe_image) {
            (Some(title), Some(price), Some(image)) => {
                let title_text = title.text().collect::<Vec<_>>().join("").trim().to_string();
                let price_text = price.text().collect::<Vec<_>>().join("").trim().to_string();

                let maybe_image_url = image.value().attr("srcset");
                if let None = maybe_image_url {
                    continue;
                }
                let image_url = maybe_image_url.unwrap();

                println!("{} ({}): {}", title_text, image_url, price_text);
            }
            _ => {}
        }
    }

    Ok(vec![])
}
