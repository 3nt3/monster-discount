use crate::trinkgut::models::Listing;
use scraper::{Html, Selector};

pub async fn get_listings_by_market_id(market_id: String) -> anyhow::Result<Vec<Listing>> {
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
    let description_selector = Selector::parse(".product--description").unwrap();

    let mut listings: Vec<Listing> = vec![];
    for element in document.select(&product_selector) {
        let maybe_title = element.select(&title_selector).next();
        let maybe_price = element.select(&price_selector).next();
        let maybe_image = element.select(&image_selector).next();
        let maybe_description = element.select(&description_selector).next();

        if let (Some(title), Some(price), Some(image), Some(description)) = (maybe_title, maybe_price, maybe_image, maybe_description) {
            let title_text = title.text().collect::<Vec<_>>().join("").trim().to_string();
            let price_text = price.text().collect::<Vec<_>>().join("").trim().to_string();

            let maybe_image_url = image.value().attr("srcset");
            if maybe_image_url.is_none() {
                continue;
            }
            let image_url = maybe_image_url.unwrap();

            let description_text = description.text().collect::<Vec<_>>().join("").trim().to_string();

            // println!("{} ({}): {}", title_text, image_url, price_text);
            listings.push(Listing {
                title: title_text,
                price: price_text,
                market_id: market_id.clone(),
                description: description_text,
                image_url: image_url.to_string(),
            });
        }
    }

    Ok(listings)
}

pub async fn get_market_id(market_name: String) -> anyhow::Result<String> {
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
    Ok(market_id.to_string())
}

pub async fn is_product_discounted<S: Into<String>>(market_id: S, product_name: S) -> anyhow::Result<bool> {
    let market_id = market_id.into();
    let product_name = product_name.into();
    let listings = get_listings_by_market_id(market_id).await?;

    for listing in listings {
        if listing.title.contains(&product_name) {
            return Ok(true);
        }
    }

    Ok(false)
}

// tests
#[cfg(not(tests))]
pub mod tests {
    #[tokio::test]
    async fn test_get_market_id() {
        let market_id = crate::trinkgut::scrape::get_market_id("elke-luck-ii".to_string()).await;
        assert!(market_id.is_ok());

        // NOTE: this may very likely change sometime
        assert!(market_id.unwrap() == "390");
    }

    #[tokio::test]
    async fn test_get_listings_by_market_id() {
        // 390 is the market id of "Elke Luck II"
        let listings = crate::trinkgut::scrape::get_listings_by_market_id("390".to_string()).await;
        assert!(listings.is_ok());

        let listings = listings.unwrap();
        assert!(!listings.is_empty());
    }

    #[tokio::test]
    async fn test_is_product_discounted() {
        let is_discounted = crate::trinkgut::scrape::is_product_discounted("390", "Krombacher").await;
        assert!(is_discounted.is_ok());
    }
}

