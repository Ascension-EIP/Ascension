use axum::{
    Extension,
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
};

use crate::{
    domain::{
        auth::error::AuthError,
        user::models::user::{Role, User},
    },
    inbound::http::AppState,
};
impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        StatusCode::UNAUTHORIZED.into_response()
    }
}

pub async fn auth(State(state): State<AppState>, mut req: Request, next: Next) -> Response {
    let token = match req
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .map(|v| v.to_string())
    {
        Some(token) => token,
        None => {
            return StatusCode::UNAUTHORIZED.into_response();
        }
    };
    let user = match state.auth_service.get_user_by_token(token).await {
        Ok(user) => user,
        Err(e) => return e.into_response(),
    };
    req.extensions_mut().insert(user);
    next.run(req).await
}

pub async fn admin(Extension(user): Extension<User>, req: Request, next: Next) -> Response {
    if user.role != Role::Admin {
        return StatusCode::FORBIDDEN.into_response();
    }
    next.run(req).await
}

#[allow(dead_code)]
pub async fn user(Extension(user): Extension<User>, req: Request, next: Next) -> Response {
    if user.role != Role::User {
        return StatusCode::FORBIDDEN.into_response();
    }
    next.run(req).await
}
