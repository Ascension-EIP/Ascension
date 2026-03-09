mod config;
mod domain;
mod inbound;
mod outbound;
#[cfg(test)]
mod tests;
mod usecase;

use std::sync::Arc;

use anyhow::Context;
use config::Config;
use inbound::http::{HttpServer, HttpServerConfig};
use outbound::postgresql::Postgres;
use sqlx::postgres::PgPoolOptions;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::{
    domain::{auth::inbound::AuthService, user::inbound::UserService},
    usecase::{auth, user},
};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv::dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let config = Arc::new(Config::load()?);

    let pool = PgPoolOptions::new()
        .max_connections(50)
        .connect(&config.database_url)
        .await
        .context(format!("could not connect to {}", &config.database_url))?;

    let repo = Arc::new(Postgres::new(pool.clone()));

    let auth_service: Arc<dyn AuthService> =
        Arc::new(auth::Service::new(repo.clone(), config.hmac_key.clone()));
    let user_service: Arc<dyn UserService> = Arc::new(user::Service::new(repo.clone()));

    let server_config = HttpServerConfig {
        port: &config.server_port,
    };
    let http_server = HttpServer::new(user_service, auth_service, server_config).await?;
    http_server.run().await
}
