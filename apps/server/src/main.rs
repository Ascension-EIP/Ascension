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
use outbound::minio::MinioClient;
use outbound::postgresql::Postgres;
use outbound::rabbitmq::RabbitMqPublisher;
use sqlx::postgres::PgPoolOptions;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::{
    domain::{auth::inbound::AuthService, user::inbound::UserService},
    usecase::{auth, user},
};
use crate::usecase::analysis::AnalysisServiceImpl;
use crate::usecase::video::VideoServiceImpl;

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

    // ── PostgreSQL ─────────────────────────────────────────────────────────────
    let pool = PgPoolOptions::new()
        .max_connections(50)
        .connect(&config.database_url)
        .await
        .context(format!("could not connect to {}", &config.database_url))?;

    if config.run_migration {
        tracing::info!("running database migrations…");
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .context("failed to run database migrations")?;
    }

    let repo = Arc::new(Postgres::new(pool.clone()));

    let auth_service: Arc<dyn AuthService> =
        Arc::new(auth::Service::new(repo.clone(), config.hmac_key.clone()));
    let user_service: Arc<dyn UserService> = Arc::new(user::Service::new(repo.clone()));
  
    // ── MinIO ──────────────────────────────────────────────────────────────────
    let minio = Arc::new(MinioClient::new(
        &config.minio_endpoint,
        &config.minio_access_key,
        &config.minio_secret_key,
        &config.minio_bucket,
    ));

    minio
        .ensure_bucket()
        .await
        .context("failed to ensure MinIO bucket exists")?;

    // ── RabbitMQ ───────────────────────────────────────────────────────────────
    let mq = Arc::new(
        RabbitMqPublisher::connect(&config.rabbitmq_url)
            .await
            .context("could not connect to RabbitMQ")?,
    );

    // ── Services ───────────────────────────────────────────────────────────────
    let auth_service: Arc<dyn crate::domain::auth::inbound::AuthService> =
        Arc::new(auth::Service::new(repo.clone(), config.hmac_key.clone()));

    let user_service: Arc<dyn crate::domain::user::ports::UserService> =
        Arc::new(Service::new(repo.clone()));

    let video_service: Arc<dyn crate::domain::video::ports::VideoService> = Arc::new(
        VideoServiceImpl::new(repo.clone(), minio.clone(), config.minio_bucket.clone()),
    );

    let analysis_service: Arc<dyn crate::domain::analysis::ports::AnalysisService> = Arc::new(
        AnalysisServiceImpl::new(repo.clone(), repo.clone(), mq.clone(), config.minio_bucket.clone()),
    );

    // ── HTTP server ────────────────────────────────────────────────────────────
    let server_config = HttpServerConfig {
        port: &config.server_port,
    };
    let http_server = HttpServer::new(
        user_service,
        auth_service,
        video_service,
        analysis_service,
        server_config,
    )
    .await?;

    http_server.run().await
}
