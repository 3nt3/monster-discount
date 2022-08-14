use sqlx::{Pool, Postgres};

pub async fn get_last_price(pool: &Pool<Postgres>) -> Result<Option<i32>, sqlx::Error> {
    let res = sqlx::query!(
        "SELECT price FROM scrapes WHERE store = 'aldinord' ORDER BY created_at DESC LIMIT 1"
    )
        .fetch_optional(pool)
        .await;

    if let Err(why) = res {
        Err(why)
    } else {
        Ok(res.unwrap().map(|x| x.price).flatten())
    }
}

pub async fn get_tokens(pool: &Pool<Postgres>) -> Result<Vec<String>, sqlx::Error> {
    let res = sqlx::query!("SELECT token FROM token__market WHERE wants_aldi = true")
        .fetch_all(pool)
        .await;

    match res {
        Err(why) => Err(why),
        Ok(data) => {
            return Ok(data
                .iter()
                .map(|record| (&record.token).to_owned())
                .collect());
        }
    }
}

// pub async fn get_average_price(pool: &Pool<Postgres>) -> Result<i32, sqlx::Error> {
//     let prices: Vec<i32> = sqlx::query!("SELECT price from scrapes where store = 'aldinord' and price is not null").fetch_all(pool).await?.iter().map(|row| row.price.unwrap()).collect();
//
//     let sum: i32 = Iterator::sum(prices.iter());
//     Ok(sum / prices.len() as i32)
// }