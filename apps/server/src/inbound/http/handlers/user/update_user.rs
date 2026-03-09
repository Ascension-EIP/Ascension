use axum::Json;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::domain::user::entity::{
    email::Email, password::Password, role::Role, user::User, username::Username,
};
use crate::domain::user::error::UserError;
use crate::inbound::http::AppState;

/// The body of a [User] update request.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub struct UpdateUserRequest {
    username: String,
    email: String,
    password: String,
    role: String,
}

/// The impl try to convert a [UpdateUserRequest] to [NewUser].
impl TryFrom<(UpdateUserRequest, String)> for User {
    type Error = anyhow::Error;

    fn try_from((value, id): (UpdateUserRequest, String)) -> Result<Self, Self::Error> {
        let id = Uuid::parse_str(&id)?;
        let name = Username::new(&value.username)?;
        let email = Email::new(&value.email)?;
        let password = Password::new(&value.password)?;
        let role = Role::new(&value.role)?;
        Ok(User::new(id, name, email, password, role))
    }
}

/// The response body data field for successful [User] update.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct UpdateUserResponse {
    id: String,
}

impl From<&User> for UpdateUserResponse {
    fn from(user: &User) -> Self {
        Self {
            id: user.id.to_string(),
        }
    }
}

/// Update an existing [User] by id.
///
/// # Responses
///
/// - 200 OK: the [User] was successfully updated.
/// - 404 Not Found: no [User] with the given id exists.
/// - 422 Unprocessable Entity: the provided id or fields are invalid.
pub async fn update_user(
    Path(id): Path<String>,
    State(state): State<AppState>,
    Json(body): Json<UpdateUserRequest>,
) -> Result<(StatusCode, Json<UpdateUserResponse>), UserError> {
    let req = (body, id).try_into()?;
    state
        .user_service
        .update_user(&req)
        .await
        .map(|ref user| (StatusCode::OK, Json(UpdateUserResponse::from(user))))
}
