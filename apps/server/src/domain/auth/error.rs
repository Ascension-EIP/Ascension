use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error)]
pub enum AuthError {
    #[error("token failed to generate")]
    #[allow(dead_code)]
    TokenGeneration,
    #[error("invalid token")]
    InvalidToken,
    #[error("token expired")]
    ExpiredToken,
    #[error("invalid token field sub")]
    InvalidTokenSub,
    #[error("user not found {0}")]
    UserNotFound(Uuid),
    #[error("invalid credentials")]
    InvalidCredentials,
    #[error("email already registered")]
    DuplicateEmail,
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}
