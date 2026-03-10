use axum::{
    Extension,
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
};
use tower_cookies::Cookies;

use crate::domain::{
    auth::error::AuthError,
    user::entity::{role::Role, user::User},
};
use crate::inbound::http::AppState;
use crate::inbound::http::handlers::auth::login::SESSION_COOKIE;

/// Extract the JWT from the request.
///
/// Lookup order (first match wins):
/// 1. `Authorization: Bearer <token>` header.
/// 2. `session_token` HttpOnly cookie set by `/v1/auth/login` or `/v1/auth/register`.
fn extract_token(req: &Request, cookies: &Cookies) -> Option<String> {
    // 1. Bearer header
    if let Some(token) = req
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .map(|v| v.to_string())
    {
        return Some(token);
    }

    // 2. Session cookie
    cookies.get(SESSION_COOKIE).map(|c| c.value().to_string())
}

/// Authentication middleware – validates the JWT and injects the [User] into
/// the request extensions so downstream handlers can access it via
/// `Extension<User>`.
pub async fn auth(
    State(state): State<AppState>,
    cookies: Cookies,
    mut req: Request,
    next: Next,
) -> Response {
    let token = match extract_token(&req, &cookies) {
        Some(t) => t,
        None => return StatusCode::UNAUTHORIZED.into_response(),
    };

    let user = match state.auth_service.get_user_by_token(token).await {
        Ok(user) => user,
        Err(e) => return AuthError::into_response(e),
    };
    req.extensions_mut().insert(user);
    next.run(req).await
}

/// Require the authenticated user to have the `Admin` role.
pub async fn admin(Extension(user): Extension<User>, req: Request, next: Next) -> Response {
    if user.role != Role::Admin {
        return StatusCode::FORBIDDEN.into_response();
    }
    next.run(req).await
}

/// Require the authenticated user to have the `User` role.
#[allow(dead_code)]
pub async fn user(Extension(user): Extension<User>, req: Request, next: Next) -> Response {
    if user.role != Role::User {
        return StatusCode::FORBIDDEN.into_response();
    }
    next.run(req).await
}
