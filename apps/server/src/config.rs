use anyhow::Context;
use std::env;

const DATABASE_URL: &str = "DATABASE_URL";
const SERVER_PORT: &str = "SERVER_PORT";
const HMAC_KEY: &str = "JWT_KEY";
const RUN_MIGRATION: &str = "RUN_MIGRATION";
const RABBITMQ_URL: &str = "RABBITMQ_URL";
const MINIO_ENDPOINT: &str = "MINIO_ENDPOINT";
const MINIO_ACCESS_KEY: &str = "MINIO_ROOT_USER";
const MINIO_SECRET_KEY: &str = "MINIO_ROOT_PASSWORD";
const MINIO_BUCKET: &str = "MINIO_BUCKET";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Config {
    /// The connection URL for the Postgres database this application should use.
    pub database_url: String,

    /// Run the runtime database migration.
    pub run_migration: bool,

    /// The port this application should use.
    pub server_port: String,

    /// The HMAC signing and verification key used for login tokens (JWTs).
    pub hmac_key: String,

    /// AMQP URL for RabbitMQ, e.g. amqp://user:pass@rabbitmq:5672
    pub rabbitmq_url: String,

    /// MinIO / S3-compatible endpoint, e.g. http://minio:9000
    pub minio_endpoint: String,

    /// MinIO access key (MINIO_ROOT_USER)
    pub minio_access_key: String,

    /// MinIO secret key (MINIO_ROOT_PASSWORD)
    pub minio_secret_key: String,

    /// MinIO bucket to store climbing videos
    pub minio_bucket: String,
}

impl Config {
    pub fn load() -> anyhow::Result<Self> {
        let database_url = load_env(DATABASE_URL)?;
        let server_port = load_env(SERVER_PORT).unwrap_or("8080".into());
        let hmac_key = load_env(HMAC_KEY)?;
        let run_migration = load_env(RUN_MIGRATION).unwrap_or("false".into()) == "true";
        let rabbitmq_url = load_env(RABBITMQ_URL)?;
        let minio_endpoint = load_env(MINIO_ENDPOINT)?;
        let minio_access_key = load_env(MINIO_ACCESS_KEY)?;
        let minio_secret_key = load_env(MINIO_SECRET_KEY)?;
        let minio_bucket = load_env(MINIO_BUCKET).unwrap_or("videos".into());

        Ok(Config {
            database_url,
            run_migration,
            server_port,
            hmac_key,
            rabbitmq_url,
            minio_endpoint,
            minio_access_key,
            minio_secret_key,
            minio_bucket,
        })
    }
}

fn load_env(key: &str) -> anyhow::Result<String> {
    env::var(key).with_context(|| format!("failed to load environment variable {}", key))
}
