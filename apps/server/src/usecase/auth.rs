use std::sync::Arc;

use async_trait::async_trait;
use uuid::Uuid;

use crate::domain::{
    auth::{error::AuthError, inbound::AuthService},
    user::{
        models::user::{EmailAddress, Password, Role, User, Username},
        ports::{UserRepository, UserRepositoryError},
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

impl From<UserRepositoryError> for AuthError {
    fn from(value: UserRepositoryError) -> Self {
        match value {
            UserRepositoryError::NotFoundId { id } => AuthError::UserNotFound(id),
            UserRepositoryError::DuplicateEmail { email } => {
                AuthError::Unknown(UserRepositoryError::DuplicateEmail { email }.into())
            }
            UserRepositoryError::Unknown(cause) => AuthError::Unknown(cause),
        }
    }
}

#[async_trait]
impl<R> AuthService for Service<R>
where
    R: UserRepository,
{
    async fn get_user_by_token(&self, token: String) -> Result<User, AuthError> {
        let user = self
            .repo
            .get_user(&crate::domain::user::ports::GetUserData { id: Uuid::new_v4() })
            .await?;
        let user = User {
            id: Uuid::new_v4(),
            username: Username::new("ouiouioui").unwrap(),
            email: EmailAddress::new("oui@oui.oui").unwrap(),
            password: Password::new("ouiouioui").unwrap(),
            role: Role::Admin,
        };
        Ok(user)
    }
}
