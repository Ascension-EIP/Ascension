use thiserror::Error;
use uuid::Uuid;

use crate::domain::user::entity::email::Email;

#[derive(Debug, Error)]
pub enum UserError {
    #[error("user with email address {0} already exists")]
    DuplicateEmail(Email),
    #[error("user {0} not found")]
    UserNotFound(Uuid),
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}
