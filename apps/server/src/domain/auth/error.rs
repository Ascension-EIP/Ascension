use thiserror::Error;

#[derive(Debug, Error)]
pub enum AuthServiceError {
    #[error("token is expired")]
    ExpiredToken,
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}
