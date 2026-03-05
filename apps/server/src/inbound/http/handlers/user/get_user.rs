use crate::domain::user::models::user::{GetUserError, GetUserInput, GetUserOutput};
use crate::domain::user::ports::UserService;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};
use crate::inbound::http::AppState;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use serde::Serialize;
use thiserror::Error;

impl From<GetUserError> for ApiError {
    fn from(e: GetUserError) -> Self {
        match e {
            GetUserError::NotFoundUser { id } => {
                Self::NotFound(format!("user id {} not found", id))
            }
            GetUserError::Unknown(_cause) => {
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

#[derive(Debug, Clone, Error)]
enum ParseGetUserHttpRequestError {
    #[error(transparent)]
    Id(#[from] uuid::Error),
}

impl From<ParseGetUserHttpRequestError> for ApiError {
    fn from(e: ParseGetUserHttpRequestError) -> Self {
        let message = match e {
            ParseGetUserHttpRequestError::Id(_cause) => {
                "id is invalid".to_string()
            }
        };

        Self::UnprocessableEntity(message)
    }
}


/// The response body for successful [User] retrieval.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct GetUserResponse {
    pub id: String,
    pub username: String,
    pub email: String,
    pub role: String,
}

impl From<GetUserOutput> for GetUserResponse {
    fn from(output: GetUserOutput) -> Self {
        Self {
            id: output.id.to_string(),
            username: output.username.to_string(),
            email: output.email.to_string(),
            role: output.role.to_string(),
        }
    }
}

pub async fn get_user<US: UserService>(
    Path(id): Path<String>,
    State(state): State<AppState<US>>,
) -> Result<ApiSuccess<GetUserResponse>, ApiError> {
    let uuid = uuid::Uuid::parse_str(&id).map_err(ParseGetUserHttpRequestError::from)?;
    let input = GetUserInput::new(uuid);

    state
        .user_service
        .get_user(&input)
        .await
        .map_err(ApiError::from)
        .map(|output| ApiSuccess::new(StatusCode::OK, GetUserResponse::from(output)))
}
