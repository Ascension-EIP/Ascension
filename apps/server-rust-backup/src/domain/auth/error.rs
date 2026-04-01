use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error)]
pub enum AuthError {
    #[error("token failed to generate")]
    #[allow(dead_code)]
    TokenGeneration,
    #[error("invalid token")]
    #[allow(dead_code)]
    InvalidToken,
    #[error("token expired")]
    #[allow(dead_code)]
    ExpiredToken,
    #[error("invalid token field sub")]
    #[allow(dead_code)]
    InvalidTokenSub,
    #[error("user not found {0}")]
    UserNotFound(Uuid),
    #[error("invalid credentials")]
    InvalidCredentials,
    #[error("email already registered")]
    DuplicateEmail,
    #[error("validation error: {0}")]
    ValidationError(String),
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}
