use anyhow::Context;
use std::env;

const DATABASE_URL: &str = "DATABASE_URL";
const SERVER_PORT: &str = "SERVER_PORT";
const HMAC_KEY: &str = "JWT_KEY";
const RUN_MIGRATION: &str = "RUN_MIGRATION";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Config {
    /// The connection URL for the Postgres database this application should use.
    pub database_url: String,
    /// Run the runtime database migration.
    pub run_migration: bool,

    /// The port this application should use.
    pub server_port: String,

    /// The HMAC signing and verification key used for login tokens (JWTs).
    ///
    /// There is no required structure or format to this key as it's just fed into a hash function.
    /// In practice, it should be a long, random string that would be infeasible to brute-force.
    pub hmac_key: String,
}

impl Config {
    pub fn load() -> anyhow::Result<Self> {
        let database_url = load_env(DATABASE_URL)?;
        let server_port = load_env(SERVER_PORT).unwrap_or("8080".into());
        let hmac_key = load_env(HMAC_KEY)?;
        let run_migration = load_env(RUN_MIGRATION).unwrap_or("false".into()) == "true";

        Ok(Config {
            database_url,
            run_migration,
            server_port,
            hmac_key,
        })
    }
}

fn load_env(key: &str) -> anyhow::Result<String> {
    env::var(key).with_context(|| format!("failed to load environment variable {}", key))
}
