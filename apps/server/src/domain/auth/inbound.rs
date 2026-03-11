use async_trait::async_trait;

use crate::domain::{
    auth::{
        entity::{AuthToken, LoginCredentials},
        error::AuthError,
    },
    user::entity::{new_user::NewUser, user::User},
};

#[async_trait]
pub trait AuthService: Send + Sync {
    /// Validate a JWT and return the associated [User].
    #[allow(dead_code)]
    async fn get_user_by_token(&self, token: String) -> Result<User, AuthError>;

    /// Register a new user account. The password is hashed before storage.
    ///
    /// # Errors
    ///
    /// - [AuthError::DuplicateEmail] if the email is already taken.
    async fn register(&self, req: &NewUser) -> Result<AuthToken, AuthError>;

    /// Authenticate an existing user with email + password.
    ///
    /// # Errors
    ///
    /// - [AuthError::InvalidCredentials] if the email does not exist or the password is wrong.
    async fn login(&self, credentials: &LoginCredentials) -> Result<AuthToken, AuthError>;
}
