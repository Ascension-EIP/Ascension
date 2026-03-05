mod config;
mod domain;
mod inbound;
mod outbound;

use config::Config;
use inbound::http::{HttpServer, HttpServerConfig};
use outbound::postgresql::Postgres;

use crate::domain::user::service::Service;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv::dotenv().ok();

    let config = Config::load()?;

    let db = Postgres::new(&config.database_url).await?;

    let user_service = Service::new(db);

    let server_config = HttpServerConfig {
        port: &config.server_port,
    };
    let http_server = HttpServer::new(user_service, server_config).await?;
    http_server.run().await
}
