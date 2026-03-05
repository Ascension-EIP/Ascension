use axum::extract::{Query, State};
use axum::http::StatusCode;
use axum::Json;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use crate::domain::user::models::user::{CreateUserOutput, GetUserError, ListUserOutput, ListUsersError, ListUsersInput, ListUsersOutput, User};
use crate::domain::user::ports::UserService;
use crate::inbound::http::AppState;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};
use crate::inbound::http::handlers::user::create_user::CreateUserResponse;
use crate::inbound::http::handlers::user::get_user::GetUserResponse;

impl From<ListUsersError> for ApiError {
    fn from(e: ListUsersError) -> Self {
        match e {
            ListUsersError::Unknown(_cause) => {
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

pub struct ListUsersParams {
    pub page: usize,
    pub limit: usize,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ListUserResponse {
    pub id: String,
    pub username: String,
    pub email: String,
    pub role: String,
}

impl From<&ListUserOutput> for ListUserResponse {
    fn from(output: &ListUserOutput) -> Self {
        Self {
            id: output.id.to_string(),
            username: output.username.to_string(),
            email: output.email.to_string(),
            role: output.role.to_string(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ListUsersResponse {
    pub users: Vec<ListUserResponse>
}

impl From<&ListUsersOutput> for ListUsersResponse {
    fn from(output: &ListUsersOutput) -> Self {
        Self {
            users: output.users.iter().map(ListUserResponse::from).collect(),
        }
    }
}

pub async fn list_users<US: UserService>(
    State(state): State<AppState<US>>,
    Query(params): Query<ListUsersParams>,
) -> Result<ApiSuccess<ListUsersResponse>, ApiError> {
    let input = ListUsersInput::new(params.page, params.limit);
    state
        .user_service
        .list_users(&input)
        .await
        .map_err(ApiError::from)
        .map(|output| ApiSuccess::new(StatusCode::OK, ListUsersResponse::from(&output)))
}
