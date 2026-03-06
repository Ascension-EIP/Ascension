use std::sync::Arc;

use async_trait::async_trait;
use uuid::Uuid;

use crate::domain::{
    auth::{error::AuthServiceError, inbound::AuthService},
    user::{
        models::user::{EmailAddress, Password, Role, User, Username},
        ports::UserRepository,
    },
};

#[derive(Debug, Clone)]
pub struct Service<R>
where
    R: UserRepository,
{
    repo: Arc<R>,
    hmac_key: String,
}

impl<R> Service<R>
where
    R: UserRepository,
{
    pub fn new(repo: Arc<R>, hmac_key: String) -> Self {
        Self { repo, hmac_key }
    }
}

#[async_trait]
impl<R> AuthService for Service<R>
where
    R: UserRepository,
{
    async fn get_user_by_token(&self, token: String) -> Result<User, AuthServiceError> {
        let user = User::new(
            Uuid::new_v4(),
            Username::new("ouiouioui").unwrap(),
            EmailAddress::new("oui@oui.oui").unwrap(),
            Password::new("ouiouioui").unwrap(),
            Role::Admin,
        );
        Ok(user)
    }
}
