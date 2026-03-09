use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
};

use crate::domain::user::error::UserError;

impl IntoResponse for UserError {
    fn into_response(self) -> Response {
        match self {
            UserError::DuplicateEmail(email) => (
                StatusCode::UNPROCESSABLE_ENTITY,
                format!("email {} already exists", email),
            )
                .into_response(),
            UserError::UserNotFound(id) => (
                StatusCode::UNPROCESSABLE_ENTITY,
                format!("user {} not found", id),
            )
                .into_response(),
            UserError::Unknown(cause) => {
                tracing::error!("{:?}\n{}", cause, cause.backtrace());
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Internal server error".to_string().into_response(),
                )
                    .into_response()
            }
        }
    }
}
