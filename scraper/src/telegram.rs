use teloxide::{
    payloads::SendMessageSetters,
    prelude::*,
    types::{InlineKeyboardButton, InlineKeyboardMarkup},
    utils::command::BotCommands,
};

use std::error::Error;

use crate::rewe_api;

#[derive(BotCommands, Clone)]
#[command(rename = "lowercase", description = "These commands are supported:")]
enum Command {
    Help,
    #[command(description = "search markets")]
    SearchMarkets(String),
    ChooseMarket(String),
    #[command(description = "get markets")]
    GetMarkets,
    #[command(description = "is monster cheap?")]
    IsMonsterCheap,
}

pub async fn run() {
    pretty_env_logger::init();

    let bot = Bot::from_env().auto_send();

    dbg!(teloxide::commands_repl(bot, answer, Command::ty()).await);
}

async fn answer(
    bot: AutoSend<Bot>,
    message: Message,
    command: Command,
) -> Result<(), Box<dyn Error + Send + Sync>> {
    match command {
        Command::Help => {
            bot.send_message(message.chat.id, Command::descriptions().to_string())
                .await?;
        }
        Command::SearchMarkets(query) => {
            let res = rewe_api::market_search(&query).await;
            match res {
                Err(err) => {
                    bot.send_message(message.chat.id, format!("some error happened: {}", err))
                        .await?;
                }
                Ok(markets) => {
                    if markets.is_empty() {
                        bot.send_message(message.chat.id, format!("nothing found for '{}'", query))
                            .await?;
                    } else {
                        let mut keyboard: Vec<Vec<InlineKeyboardButton>> = vec![];

                        for three_markets in markets.chunks(3) {
                            let row = three_markets
                                .iter()
                                .map(|market| {
                                    InlineKeyboardButton::callback(
                                        market.address.street.to_owned(),
                                        format!("/choose {}", market.id.to_owned()),
                                    )
                                })
                                .collect();
                            keyboard.push(row);
                        }

                        bot.send_message(
                            message.chat.id,
                            format!("found these {} results:", markets.len()),
                        )
                        .reply_markup(InlineKeyboardMarkup::new(keyboard))
                        .await?;
                    }
                }
            }
        }
        _ => {}
    }

    Ok(())
}
