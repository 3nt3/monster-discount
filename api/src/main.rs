#[macro_use]
extern crate rocket;

use std::env;

use rocket::http::Status;
use rocket::State;

use anyhow::Result;

use sqlx::postgres::PgPoolOptions;
use sqlx::{Executor, Pool, Postgres};

use rocket::serde::{json::Json, Deserialize, Serialize};

// #[derive(Debug)]
// pub struct User {
//     pub markets: Vec<u32>,
// }
//
// impl User {
//     pub async fn find_by_id(id: i32, pool: &Pool<Postgres>) -> Result<User> {
//         let user = sqlx::query_as!(User, "SELECT * FROM my_table WHERE id = $1", id)
//             .fetch_one(&*pool)
//             .await?;
//
//         Ok(user)
//     }
// }

#[derive(Deserialize, Debug, Serialize)]
pub struct User {
    pub markets: Vec<i32>,
    pub token: String,
}

#[post("/watch-markets", data = "<data>")]
async fn watch_markets(pool: &State<Pool<Postgres>>, data: Json<User>) -> Result<Status, Status> {
    let delete_res = sqlx::query!("DELETE FROM token__market WHERE token = $1", data.token)
        .execute(&**pool)
        .await;
    if let Err(err) = delete_res {
        return Err(Status::InternalServerError);
    }

    // probably not very performant to do it like this but who cares
    for market in &data.markets {
        let insert_res = sqlx::query!("INSERT INTO markets (id) VALUES ($1)", market)
            .execute(&**pool)
            .await;

        let insert2_res = sqlx::query!(
            "INSERT INTO token__market (token, market_id) VALUES ($1, $2)",
            data.token,
            market
        )
        .execute(&**pool)
        .await;

        dbg!(insert2_res);
    }

    Ok(Status::NoContent)
}

#[get("/watched-markets/<token>")]
async fn watched_markets(
    pool: &State<Pool<Postgres>>,
    token: String,
) -> Result<Json<User>, Status> {
    let res = sqlx::query!(
        "SELECT market_id FROM token__market WHERE token = $1",
        token
    )
    .fetch_all(&**pool)
    .await;

    match res {
        Ok(data) => {
            println!("{:?}", data);
            return Ok(Json(User {
                markets: data.iter().map(|x| x.market_id).collect(),
                token,
            }));
        }
        Err(_) => Err(Status::InternalServerError),
    }
}

#[rocket::main]
async fn main() -> Result<()> {
    dotenv::dotenv();
    let database_url = env::var("DATABASE_URL")?;

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    sqlx::migrate!("db/migrations").run(&pool).await?;

    rocket::build()
        .mount("/", routes![watch_markets, watched_markets])
        .manage(pool)
        .launch()
        .await?;

    Ok(())
}
