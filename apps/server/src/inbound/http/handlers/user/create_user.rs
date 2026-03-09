use axum::http::StatusCode;
use axum::{Json, extract::State};
use serde::{Deserialize, Serialize};

use crate::domain::user::{
    entity::{
        email::Email, new_user::NewUser, password::Password, role::Role, user::User,
        username::Username,
    },
    error::UserError,
};
use crate::inbound::http::AppState;

/// The body of a [User] creation request.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub struct CreateUserRequest {
    username: String,
    email: String,
    password: String,
    role: String,
}

/// The impl try to convert a [CreateUserRequest] to [NewUser].
impl TryFrom<CreateUserRequest> for NewUser {
    type Error = anyhow::Error;

    fn try_from(value: CreateUserRequest) -> Result<Self, Self::Error> {
        let name = Username::new(&value.username)?;
        let email = Email::new(&value.email)?;
        let password = Password::new(&value.password)?;
        let role = Role::new(&value.role)?;
        Ok(NewUser::new(name, email, password, role))
    }
}

/// The response body data field for successful [User] creation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct CreateUserResponse {
    id: String,
}

impl From<&User> for CreateUserResponse {
    fn from(user: &User) -> Self {
        Self {
            id: user.id.to_string(),
        }
    }
}

/// Create a new [User].
///
/// # Responses
///
/// - 201 Created: the [User] was successfully created.
/// - 422 Unprocessable entity: An [User] with the email name already exists.
pub async fn create_user(
    State(state): State<AppState>,
    Json(body): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<CreateUserResponse>), UserError> {
    let req = body.try_into()?;
    state
        .user_service
        .create_user(&req)
        .await
        .map(|ref user| (StatusCode::CREATED, Json(CreateUserResponse::from(user))))
}
