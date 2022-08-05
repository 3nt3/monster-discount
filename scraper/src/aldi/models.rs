use serde::Deserialize;

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ProductResponse {
    pub article_id: String,
    pub price: String,
}
