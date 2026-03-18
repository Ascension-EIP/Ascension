use axum::Json;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde::Serialize;
use thiserror::Error;
use utoipa::ToSchema;

use crate::domain::user::entity::user::User;
use crate::domain::user::error::UserError;
use crate::inbound::http::AppState;

#[derive(Debug, Clone, Error)]
enum GetUserRequestError {
    #[error(transparent)]
    Id(#[from] uuid::Error),
}

impl IntoResponse for GetUserRequestError {
    fn into_response(self) -> Response {
        let message = match self {
            GetUserRequestError::Id(_) => "id is invalid".to_string(),
        };

        (StatusCode::UNPROCESSABLE_ENTITY, message).into_response()
    }
}

/// The response body for successful [User] retrieval.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, ToSchema)]
pub struct GetUserResponse {
    pub id: String,
    pub username: String,
    pub email: String,
    pub role: String,
}

impl From<&User> for GetUserResponse {
    fn from(user: &User) -> Self {
        Self {
            id: user.id.to_string(),
            username: user.username.to_string(),
            email: user.email.to_string(),
            role: user.role.to_string(),
        }
    }
}

/// Get a user by UUID.
#[utoipa::path(
    get,
    path = "/v1/users/{id}",
    params(
        ("id" = String, Path, description = "User UUID"),
    ),
    responses(
        (status = 200, description = "User found", body = GetUserResponse),
        (status = 404, description = "No user with this ID"),
        (status = 422, description = "ID is not a valid UUID"),
    ),
    tag = "Users"
)]
pub async fn get_user(
    Path(id): Path<String>,
    State(state): State<AppState>,
) -> Result<(StatusCode, Json<GetUserResponse>), UserError> {
    let uuid = uuid::Uuid::parse_str(&id)
        .map_err(GetUserRequestError::from)
        .map_err(|e| anyhow::anyhow!(e))?;

    state
        .user_service
        .get_user(&uuid)
        .await
        .map(|ref user| (StatusCode::OK, Json(GetUserResponse::from(user))))
}
