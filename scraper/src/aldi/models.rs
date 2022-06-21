use serde::Deserialize;

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ProductResponse {
    article_id: String,
    price: String,
}
