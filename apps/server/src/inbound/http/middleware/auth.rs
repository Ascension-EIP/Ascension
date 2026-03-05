use axum::{
    body::Body,
    http::{Request, Response, StatusCode},
    middleware::Next,
    response::IntoResponse,
};
use uuid::Uuid;

use crate::domain::user::models::user::{EmailAddress, Password, Role, User, Username};

pub async fn auth(mut req: Request<Body>, next: Next) -> Response<Body> {
    req.extensions_mut().insert(User::new(
        Uuid::new_v4(),
        Username::new("ouiouioui").unwrap(),
        EmailAddress::new("oui@oui.oui").unwrap(),
        Password::new("oui").unwrap(),
        Role::Admin,
    ));
    next.run(req).await
}

pub async fn admin(req: Request<Body>, next: Next) -> Response<Body> {
    let user = req.extensions().get::<User>().cloned();

    let Some(user) = user else {
        return StatusCode::UNAUTHORIZED.into_response();
    };
    if user.role != Role::Admin {
        return StatusCode::FORBIDDEN.into_response();
    }
    next.run(req).await
}

pub async fn user(req: Request<Body>, next: Next) -> Response<Body> {
    let user = req.extensions().get::<User>().cloned();

    let Some(user) = user else {
        return StatusCode::UNAUTHORIZED.into_response();
    };
    if user.role != Role::User {
        return StatusCode::FORBIDDEN.into_response();
    }
    next.run(req).await
}
