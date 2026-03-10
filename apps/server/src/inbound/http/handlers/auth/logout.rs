use axum::http::StatusCode;
use axum::response::IntoResponse;
use tower_cookies::Cookies;

use super::login::SESSION_COOKIE;

/// Log out the current user by clearing the session cookie.
///
/// This endpoint always returns `204 No Content` regardless of whether the
/// caller was logged in, so it is safe to call from a "log out" button even
/// when the session has already expired.
///
/// # Responses
///
/// - `204 No Content` – cookie cleared.
pub async fn logout(cookies: Cookies) -> impl IntoResponse {
    cookies.remove(Cookie::from(SESSION_COOKIE));
    StatusCode::NO_CONTENT
}

// Re-export Cookie so callers don't need to depend on tower_cookies directly.
use tower_cookies::Cookie;
