use crate::rewe::models;
use std::{fs::File, io::Read};

pub async fn get_market_info(market_id: i32) -> Result<models::MarketInfo, reqwest::Error> {
    let http_client = reqwest::Client::builder()
        .use_rustls_tls()
        .danger_accept_invalid_certs(true)
        .build()?;

    let http_builder = http_client
        .get(format!(
            "https://mobile-api.rewe.de/mobile/markets/markets/{}",
            market_id
        ))
        .header(
            "User-Agent",
            "REWE-Mobile-App/3.4.56 Android/11 (Smartphone)",
        )
        .header("Accept", "application/json");
    let resp = http_builder.send().await?;

    Ok(resp.json::<models::MarketInfo>().await?)
}

#[cfg(not(tests))]
pub mod tests {
    use super::*;

    #[tokio::test]
    pub async fn returns_market_info() {
        let res = get_market_info(1940156).await;
        //dbg!(&res);
        assert_eq!(true, res.is_ok());
    }

    #[tokio::test]
    pub async fn gets_offers() {
        let res = get_offers(1940156).await;
        // dbg!(&res);
        assert_eq!(true, res.is_ok());
    }

    #[tokio::test]
    pub async fn gets_current_price() {
        let res = get_current_price().await;
        dbg!(&res);
        assert_eq!(true, res.is_ok());
    }
}

pub async fn get_offers(market_id: i32) -> Result<models::Response, reqwest::Error> {
    let http_client = reqwest::Client::builder()
        .use_rustls_tls()
        .danger_accept_invalid_certs(true)
        .build()?;
    let http_builder = http_client
        .get("https://mobile-api.rewe.de/api/v3/all-offers")
        .query(&[("marketCode", market_id)])
        .header("ruleversion", "3")
        .header("rd-market-id", market_id)
        .header("accept-encoding", "gzip")
        .header(
            "User-Agent",
            "REWE-Mobile-App/3.4.56 Android/11 (Smartphone)",
        );
    // .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0");

    let resp = http_builder.send().await?;

    resp.json::<models::Response>().await
}

pub async fn market_search(query: &str) -> Result<Vec<models::MarketInfo>, reqwest::Error> {
    let http_client = reqwest::Client::builder()
        .use_rustls_tls()
        .danger_accept_invalid_certs(true)
        .build()?;
    let http_builder = http_client
        .get("https://mobile-api.rewe.de/api/v3/all-offers")
        .query(&[("query", query)])
        .header(
            "User-Agent",
            "Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0",
        );
    let resp = http_builder.send().await;
    if let Err(err) = resp {
        return Err(err);
    }
    resp.unwrap()
        .json::<models::MarketSearchResponse>()
        .await
        .map(|x| x.items)
}

pub async fn get_current_price() -> Result<models::ProductResponse, reqwest::Error> {
    let http_client = reqwest::Client::builder()
        .use_rustls_tls()
        .danger_accept_invalid_certs(true)
        .build()?;
    let http_builder = http_client
        .get("https://mobile-api.rewe.de/mobile/products/13-5060337500401-f2bf8a20-3ff3-4fbc-9cea-984edf862b0f")
        .header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0");
    let resp = http_builder.send().await;
    if let Err(err) = resp {
        return Err(err);
    }

    resp.unwrap().json::<models::ProductResponse>().await
}
