use crate::domain::auth::inbound::AuthService;
use crate::domain::user::models::user::{DeleteUserError, DeleteUserInput};
use crate::domain::user::ports::UserService;
use crate::inbound::http::AppState;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};
use axum::extract::{Path, State};
use axum::http::StatusCode;
use serde::Serialize;
use thiserror::Error;

impl From<DeleteUserError> for ApiError {
    fn from(e: DeleteUserError) -> Self {
        match e {
            DeleteUserError::NotFoundUser { id } => {
                Self::NotFound(format!("user id {} not found", id))
            }
            DeleteUserError::Unknown(_cause) => {
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

#[derive(Debug, Clone, Error)]
enum ParseDeleteUserHttpRequestError {
    #[error(transparent)]
    Id(#[from] uuid::Error),
}

impl From<ParseDeleteUserHttpRequestError> for ApiError {
    fn from(e: ParseDeleteUserHttpRequestError) -> Self {
        let message = match e {
            ParseDeleteUserHttpRequestError::Id(_cause) => "id is invalid".to_string(),
        };

        Self::UnprocessableEntity(message)
    }
}

/// The response body for successful [User] deletion.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct DeleteUserResponse {}

pub async fn delete_user<US: UserService, AS: AuthService>(
    Path(id): Path<String>,
    State(state): State<AppState<US, AS>>,
) -> Result<ApiSuccess<DeleteUserResponse>, ApiError> {
    let uuid = uuid::Uuid::parse_str(&id).map_err(ParseDeleteUserHttpRequestError::from)?;
    let input = DeleteUserInput::new(uuid);

    state
        .user_service
        .delete_user(&input)
        .await
        .map_err(ApiError::from)
        .map(|_| ApiSuccess::new(StatusCode::OK, DeleteUserResponse {}))
}
