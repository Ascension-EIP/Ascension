use async_trait::async_trait;

use crate::domain::{auth::error::AuthError, user::entity::user::User};

#[async_trait]
pub trait AuthService: Send + Sync {
    async fn get_user_by_token(&self, token: String) -> Result<User, AuthError>;
}
