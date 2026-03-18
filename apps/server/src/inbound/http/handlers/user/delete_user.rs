use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::response::Response;
use thiserror::Error;

use crate::domain::user::error::UserError;
use crate::inbound::http::AppState;

#[derive(Debug, Clone, Error)]
enum DeleteUserRequestError {
    #[error(transparent)]
    Id(#[from] uuid::Error),
}

impl IntoResponse for DeleteUserRequestError {
    fn into_response(self) -> Response {
        let message = match self {
            DeleteUserRequestError::Id(_) => "id is invalid".to_string(),
        };

        (StatusCode::UNPROCESSABLE_ENTITY, message).into_response()
    }
}

/// Permanently delete a user.
#[utoipa::path(
    delete,
    path = "/v1/users/{id}",
    params(
        ("id" = String, Path, description = "User UUID"),
    ),
    responses(
        (status = 200, description = "User deleted"),
        (status = 404, description = "No user with this ID"),
        (status = 422, description = "ID is not a valid UUID"),
    ),
    tag = "Users"
)]
pub async fn delete_user(
    Path(id): Path<String>,
    State(state): State<AppState>,
) -> Result<(StatusCode, ()), UserError> {
    let uuid = uuid::Uuid::parse_str(&id)
        .map_err(DeleteUserRequestError::from)
        .map_err(|e| anyhow::anyhow!(e))?;

    state
        .user_service
        .delete_user(&uuid)
        .await
        .map(|output| (StatusCode::OK, output))
}
