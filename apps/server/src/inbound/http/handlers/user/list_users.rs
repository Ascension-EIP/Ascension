use axum::Json;
use axum::extract::{Query, State};
use axum::http::StatusCode;
use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};

use crate::domain::user::entity::pagination::Pagination;
use crate::domain::user::entity::user::User;
use crate::domain::user::error::UserError;
use crate::inbound::http::AppState;

#[derive(Deserialize, IntoParams)]
pub struct QueryPagination {
    /// Page number (1-based, default: 1)
    pub page: Option<usize>,
    /// Items per page (default: 20)
    pub per_page: Option<usize>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, ToSchema)]
pub struct ListUserResponse {
    pub id: String,
    pub username: String,
    pub email: String,
    pub role: String,
}

impl From<&User> for ListUserResponse {
    fn from(user: &User) -> Self {
        Self {
            id: user.id.to_string(),
            username: user.username.to_string(),
            email: user.email.to_string(),
            role: user.role.to_string(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, ToSchema)]
pub struct ListUsersResponse {
    pub users: Vec<ListUserResponse>,
}

impl From<&Vec<User>> for ListUsersResponse {
    fn from(users: &Vec<User>) -> Self {
        Self {
            users: users.iter().map(ListUserResponse::from).collect(),
        }
    }
}

/// List all users (paginated).
#[utoipa::path(
    get,
    path = "/v1/users",
    params(QueryPagination),
    responses(
        (status = 200, description = "List of users", body = ListUsersResponse),
    ),
    tag = "Users"
)]
pub async fn list_users(
    State(state): State<AppState>,
    Query(params): Query<QueryPagination>,
) -> Result<(StatusCode, Json<ListUsersResponse>), UserError> {
    let input = Pagination {
        page: params.page,
        per_page: params.per_page,
    };

    state
        .user_service
        .list_users(&input)
        .await
        .map(|ref users| (StatusCode::OK, Json(ListUsersResponse::from(users))))
}
