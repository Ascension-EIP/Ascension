use axum::{Json, extract::State, http::StatusCode};
use serde::{Deserialize, Serialize};
use tower_cookies::{Cookie, Cookies};
use utoipa::ToSchema;

use super::login::SESSION_COOKIE;
use crate::domain::{
    auth::error::AuthError,
    user::entity::{
        email::Email, new_user::NewUser, password::Password, role::Role, username::Username,
    },
};
use crate::inbound::http::AppState;

/// Request body for `POST /v1/auth/register`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct RegisterRequest {
    /// 8–24 characters, alphanumeric + underscores only
    #[schema(example = "climber42")]
    username: String,
    /// Must be a valid email address
    #[schema(example = "climber@example.com")]
    email: String,
    /// Minimum 8 characters
    #[schema(example = "securepassword")]
    password: String,
}

/// Response body for a successful registration.
#[derive(Debug, Serialize, ToSchema)]
pub struct RegisterResponse {
    /// JWT access token
    access_token: String,
    /// UUID of the newly created user
    user_id: String,
}

/// Register a new user account.
///
/// Creates a `user`-role account, hashes the password with bcrypt, and returns a JWT.
#[utoipa::path(
    post,
    path = "/v1/auth/register",
    request_body = RegisterRequest,
    responses(
        (status = 201, description = "Account created — token returned", body = RegisterResponse),
        (status = 409, description = "Email already registered"),
        (status = 422, description = "Validation failed"),
    ),
    tag = "Auth"
)]
pub async fn register(
    State(state): State<AppState>,
    cookies: Cookies,
    Json(body): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<RegisterResponse>), AuthError> {
    let username =
        Username::new(&body.username).map_err(|e| AuthError::ValidationError(e.to_string()))?;
    let email = Email::new(&body.email).map_err(|e| AuthError::ValidationError(e.to_string()))?;
    let password =
        Password::new(&body.password).map_err(|e| AuthError::ValidationError(e.to_string()))?;

    // New accounts are always created with the `User` role.
    let role = Role::User;

    let new_user = NewUser::new(username, email, password, role);
    let auth_token = state.auth_service.register(&new_user).await?;

    // Set HttpOnly session cookie so the browser carries the token automatically.
    let mut cookie = Cookie::new(SESSION_COOKIE, auth_token.token.clone());
    cookie.set_http_only(true);
    cookie.set_path("/");
    cookie.set_same_site(tower_cookies::cookie::SameSite::Strict);
    cookies.add(cookie);

    Ok((
        StatusCode::CREATED,
        Json(RegisterResponse {
            access_token: auth_token.token,
            user_id: auth_token.user_id.to_string(),
        }),
    ))
}
