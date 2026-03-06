use chrono::{DateTime, Utc};
use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error)]
pub enum AuthError {
    #[error("invalid token")]
    InvalidToken,
    #[error("token expired at {0}")]
    ExpiredToken(DateTime<Utc>),
    #[error("user not found {0}")]
    UserNotFound(Uuid),
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}
