use axum::{Json, extract::State, http::StatusCode, response::IntoResponse};
use serde::{Deserialize, Serialize};
use tower_cookies::{Cookie, Cookies};

use crate::domain::{
    auth::{entity::LoginCredentials, error::AuthError},
    user::entity::{email::Email, password::Password},
};
use crate::inbound::http::AppState;

/// Session cookie name used throughout the application.
pub const SESSION_COOKIE: &str = "session_token";

/// Request body for `POST /v1/auth/login`.
#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    email: String,
    password: String,
}

/// Response body for a successful login.
#[derive(Debug, Serialize)]
pub struct LoginResponse {
    token: String,
}

/// Authenticate a user with email and password.
///
/// On success the JWT is:
/// 1. Returned in the JSON body as `token`.
/// 2. Set as an `HttpOnly; SameSite=Strict` session cookie named `session_token`.
///
/// # Responses
///
/// - `200 OK` – valid credentials, token returned.
/// - `401 Unauthorized` – wrong email or password.
/// - `422 Unprocessable Entity` – malformed request fields.
pub async fn login(
    State(state): State<AppState>,
    cookies: Cookies,
    Json(body): Json<LoginRequest>,
) -> Result<(StatusCode, Json<LoginResponse>), AuthError> {
    let email = Email::new(&body.email)
        .map_err(|e| AuthError::Unknown(anyhow::anyhow!(e)))?;
    let password = Password::new(&body.password)
        .map_err(|_| AuthError::InvalidCredentials)?;

    let credentials = LoginCredentials::new(email, password);
    let auth_token = state.auth_service.login(&credentials).await?;

    // Set HttpOnly session cookie so the browser carries the token automatically.
    let mut cookie = Cookie::new(SESSION_COOKIE, auth_token.token.clone());
    cookie.set_http_only(true);
    cookie.set_path("/");
    cookie.set_same_site(tower_cookies::cookie::SameSite::Strict);
    cookies.add(cookie);

    Ok((StatusCode::OK, Json(LoginResponse { token: auth_token.token })))
}

impl IntoResponse for AuthError {
    fn into_response(self) -> axum::response::Response {
        match self {
            AuthError::InvalidCredentials => StatusCode::UNAUTHORIZED.into_response(),
            AuthError::ExpiredToken => StatusCode::UNAUTHORIZED.into_response(),
            AuthError::InvalidToken | AuthError::InvalidTokenSub => {
                StatusCode::UNAUTHORIZED.into_response()
            }
            AuthError::UserNotFound(_) => StatusCode::NOT_FOUND.into_response(),
            AuthError::DuplicateEmail => StatusCode::CONFLICT.into_response(),
            AuthError::TokenGeneration | AuthError::Unknown(_) => {
                StatusCode::INTERNAL_SERVER_ERROR.into_response()
            }
        }
    }
}
