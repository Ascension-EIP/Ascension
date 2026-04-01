use axum::http::StatusCode;
use axum::response::IntoResponse;
use tower_cookies::Cookies;

use super::login::SESSION_COOKIE;

/// Log out the current user by clearing the session cookie.
///
/// Always returns `204 No Content` regardless of whether the caller was logged in.
#[utoipa::path(
    post,
    path = "/v1/auth/logout",
    responses(
        (status = 204, description = "Session cookie cleared"),
    ),
    tag = "Auth"
)]
pub async fn logout(cookies: Cookies) -> impl IntoResponse {
    cookies.remove(Cookie::from(SESSION_COOKIE));
    StatusCode::NO_CONTENT
}

// Re-export Cookie so callers don't need to depend on tower_cookies directly.
use tower_cookies::Cookie;
