use axum::{Json, extract::State, http::StatusCode, response::IntoResponse};
use serde::{Deserialize, Serialize};
use tower_cookies::{Cookie, Cookies};
use utoipa::ToSchema;

use crate::domain::{
    auth::{entity::LoginCredentials, error::AuthError},
    user::entity::{email::Email, password::Password},
};
use crate::inbound::http::AppState;

/// Session cookie name used throughout the application.
pub const SESSION_COOKIE: &str = "session_token";

/// Request body for `POST /v1/auth/login`.
#[derive(Debug, Deserialize, ToSchema)]
pub struct LoginRequest {
    /// Registered email address
    #[schema(example = "climber@example.com")]
    email: String,
    /// Account password (min 8 characters)
    #[schema(example = "securepassword")]
    password: String,
}

/// Response body for a successful login.
#[derive(Debug, Serialize, ToSchema)]
pub struct LoginResponse {
    /// JWT access token
    access_token: String,
    /// UUID of the authenticated user
    user_id: String,
}

/// Authenticate a user with email and password.
///
/// Returns a JWT in the body and sets an HttpOnly session cookie.
#[utoipa::path(
    post,
    path = "/v1/auth/login",
    request_body = LoginRequest,
    responses(
        (status = 200, description = "Valid credentials — token returned", body = LoginResponse),
        (status = 401, description = "Wrong email or password"),
        (status = 422, description = "Malformed request fields"),
    ),
    tag = "Auth"
)]
pub async fn login(
    State(state): State<AppState>,
    cookies: Cookies,
    Json(body): Json<LoginRequest>,
) -> Result<(StatusCode, Json<LoginResponse>), AuthError> {
    let email = Email::new(&body.email).map_err(|e| AuthError::ValidationError(e.to_string()))?;
    let password = Password::new(&body.password).map_err(|_| AuthError::InvalidCredentials)?;

    let credentials = LoginCredentials::new(email, password);
    let auth_token = state.auth_service.login(&credentials).await?;

    // Set HttpOnly session cookie so the browser carries the token automatically.
    let mut cookie = Cookie::new(SESSION_COOKIE, auth_token.token.clone());
    cookie.set_http_only(true);
    cookie.set_path("/");
    cookie.set_same_site(tower_cookies::cookie::SameSite::Strict);
    cookies.add(cookie);

    Ok((
        StatusCode::OK,
        Json(LoginResponse {
            access_token: auth_token.token,
            user_id: auth_token.user_id.to_string(),
        }),
    ))
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
            AuthError::ValidationError(_) => StatusCode::UNPROCESSABLE_ENTITY.into_response(),
            AuthError::TokenGeneration | AuthError::Unknown(_) => {
                StatusCode::INTERNAL_SERVER_ERROR.into_response()
            }
        }
    }
}
