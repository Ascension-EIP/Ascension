use std::sync::Arc;

use async_trait::async_trait;
use chrono::{Duration, Utc};
use jsonwebtoken::{
    DecodingKey, EncodingKey, Header, Validation, decode, encode, errors::ErrorKind,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::domain::{
    auth::{
        entity::{AuthToken, LoginCredentials},
        error::AuthError,
        inbound::AuthService,
    },
    user::{
        entity::{new_user::NewUser, user::User},
        error::UserError,
        outbound::UserRepository,
    },
};

// ─── JWT helper ───────────────────────────────────────────────────────────────

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

// ─── Service ──────────────────────────────────────────────────────────────────

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
            jwt: Jwt::new(secret, Duration::hours(24)),
        }
    }
}

// ─── Error conversions ────────────────────────────────────────────────────────

impl From<UserError> for AuthError {
    fn from(value: UserError) -> Self {
        match value {
            UserError::UserNotFound(id) => AuthError::UserNotFound(id),
            UserError::DuplicateEmail(_) => AuthError::DuplicateEmail,
            UserError::Unknown(cause) => AuthError::Unknown(cause),
        }
    }
}

// ─── AuthService impl ─────────────────────────────────────────────────────────

#[async_trait]
impl<R> AuthService for Service<R>
where
    R: UserRepository,
{
    /// Validate a JWT and return the [User] identified by the `sub` claim.
    async fn get_user_by_token(&self, token: String) -> Result<User, AuthError> {
        let claims = self.jwt.validate(token.as_str())?;
        let id = Uuid::parse_str(&claims.sub).map_err(|_| AuthError::InvalidTokenSub)?;
        let user = self.repo.get_user(&id).await?;
        Ok(user)
    }

    /// Register a new user. The plain-text password is hashed with bcrypt before
    /// being forwarded to the repository.
    ///
    /// # Errors
    ///
    /// - [AuthError::DuplicateEmail] if the email is already taken.
    async fn register(&self, req: &NewUser) -> Result<AuthToken, AuthError> {
        // Hash the password with bcrypt (cost 12 is a sensible default).
        let raw_password = req.password.to_string();
        let hashed =
            bcrypt::hash(&raw_password, 12).map_err(|e| AuthError::Unknown(anyhow::anyhow!(e)))?;

        let hashed_password = crate::domain::user::entity::password::Password::new(&hashed)
            .map_err(|e| AuthError::Unknown(anyhow::anyhow!(e)))?;

        let new_user = NewUser::new(
            req.username.clone(),
            req.email.clone(),
            hashed_password,
            req.role.clone(),
        );

        let user = self.repo.create_user(&new_user).await?;
        let token = self.jwt.generate(user.id)?;
        Ok(AuthToken::new(token, user.id))
    }

    /// Authenticate an existing user. Returns a JWT on success.
    ///
    /// # Errors
    ///
    /// - [AuthError::InvalidCredentials] when the email is not found or the
    ///   password does not match.
    async fn login(&self, credentials: &LoginCredentials) -> Result<AuthToken, AuthError> {
        let user = self
            .repo
            .get_user_by_email(&credentials.email)
            .await
            .map_err(|_| AuthError::InvalidCredentials)?;

        let raw_password = credentials.password.to_string();
        let stored_hash = user.password.to_string();

        let valid = bcrypt::verify(&raw_password, &stored_hash)
            .map_err(|e| AuthError::Unknown(anyhow::anyhow!(e)))?;

        if !valid {
            return Err(AuthError::InvalidCredentials);
        }

        let token = self.jwt.generate(user.id)?;
        Ok(AuthToken::new(token, user.id))
    }
}
