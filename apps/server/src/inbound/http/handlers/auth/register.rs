use axum::{Json, extract::State, http::StatusCode};
use serde::{Deserialize, Serialize};
use tower_cookies::{Cookie, Cookies};

use crate::domain::{
    auth::error::AuthError,
    user::entity::{email::Email, new_user::NewUser, password::Password, role::Role, username::Username},
};
use crate::inbound::http::AppState;
use super::login::SESSION_COOKIE;

/// Request body for `POST /v1/auth/register`.
#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    username: String,
    email: String,
    password: String,
}

/// Response body for a successful registration.
#[derive(Debug, Serialize)]
pub struct RegisterResponse {
    token: String,
}

/// Register a new user account.
///
/// The password is hashed with bcrypt before being stored.
/// On success a JWT session cookie is set and the token is returned in the body.
///
/// # Responses
///
/// - `201 Created` – account created, token returned.
/// - `409 Conflict` – email already registered.
/// - `422 Unprocessable Entity` – malformed request fields.
pub async fn register(
    State(state): State<AppState>,
    cookies: Cookies,
    Json(body): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<RegisterResponse>), AuthError> {
    let username = Username::new(&body.username)
        .map_err(|e| AuthError::Unknown(anyhow::anyhow!(e)))?;
    let email = Email::new(&body.email)
        .map_err(|e| AuthError::Unknown(anyhow::anyhow!(e)))?;
    let password = Password::new(&body.password)
        .map_err(|e| AuthError::Unknown(anyhow::anyhow!(e)))?;

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

    Ok((StatusCode::CREATED, Json(RegisterResponse { token: auth_token.token })))
}
