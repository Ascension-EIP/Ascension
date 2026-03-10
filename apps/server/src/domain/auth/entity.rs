use uuid::Uuid;

use crate::domain::user::entity::{email::Email, password::Password};

/// Credentials provided by a user attempting to log in.
#[derive(Debug, Clone)]
pub struct LoginCredentials {
    pub email: Email,
    /// Raw (un-hashed) password as entered by the user.
    pub password: Password,
}

impl LoginCredentials {
    pub fn new(email: Email, password: Password) -> Self {
        Self { email, password }
    }
}

/// The result of a successful authentication (register or login).
#[derive(Debug, Clone)]
pub struct AuthToken {
    /// Signed JWT that the client must carry in subsequent requests.
    pub token: String,
    /// The authenticated user's ID.
    pub user_id: Uuid,
}

impl AuthToken {
    pub fn new(token: String, user_id: Uuid) -> Self {
        Self { token, user_id }
    }
}
