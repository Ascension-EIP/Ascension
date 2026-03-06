use std::sync::Arc;

use async_trait::async_trait;
use chrono::{Duration, Utc};
use jsonwebtoken::{
    DecodingKey, EncodingKey, Header, Validation, decode, encode, errors::ErrorKind,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::domain::{
    auth::{error::AuthError, inbound::AuthService},
    user::{
        models::user::{Password, User},
        ports::{UserRepository, UserRepositoryError},
    },
};

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub exp: i64,
    pub iat: i64,
}

#[derive(Debug, Clone)]
struct Jwt {
    secret: String,
    duration: Duration,
}

impl Jwt {
    fn new(secret: String, duration: Duration) -> Self {
        Self { secret, duration }
    }

    pub fn generate(&self, user_id: Uuid) -> Result<String, AuthError> {
        let now = Utc::now();
        let claims = Claims {
            sub: user_id.to_string(),
            iat: now.timestamp(),
            exp: (now + self.duration).timestamp(),
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.secret.as_bytes()),
        )
        .map_err(|_| AuthError::TokenGeneration)
    }

    pub fn validate(&self, token: &str) -> Result<Claims, AuthError> {
        decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.secret.as_bytes()),
            &Validation::default(),
        )
        .map(|data| data.claims)
        .map_err(|e| match e.kind() {
            ErrorKind::ExpiredSignature => AuthError::ExpiredToken,
            _ => AuthError::InvalidToken,
        })
    }
}

#[derive(Debug, Clone)]
pub struct Service<R>
where
    R: UserRepository,
{
    repo: Arc<R>,
    jwt: Jwt,
}

impl<R> Service<R>
where
    R: UserRepository,
{
    pub fn new(repo: Arc<R>, secret: String) -> Self {
        Self {
            repo,
            jwt: Jwt::new(secret, Duration::minutes(60)),
        }
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
        let claims = self.jwt.validate(token.as_str())?;
        let id = Uuid::parse_str(&claims.sub).map_err(|_| AuthError::InvalidTokenSub)?;
        let user = self
            .repo
            .get_user(&crate::domain::user::ports::GetUserData { id })
            .await?;
        let user = User {
            id: user.id,
            username: user.username,
            email: user.email,
            password: Password::new("ouiouioui").unwrap(),
            role: user.role,
        };
        Ok(user)
    }
}
