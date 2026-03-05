use crate::domain::user::models::user::{
    EmailAddress, EmailAddressInvalidError, Password, PasswordInvalidError, Role, RoleInvalidError,
    UpdateUserError, UpdateUserInput, UpdateUserOutput, Username, UsernameInvalidError,
};
use crate::domain::user::ports::UserService;
use crate::inbound::http::AppState;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};
use axum::Json;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use serde::{Deserialize, Serialize};
use thiserror::Error;

impl From<UpdateUserError> for ApiError {
    fn from(e: UpdateUserError) -> Self {
        match e {
            UpdateUserError::DuplicateEmail { email } => {
                Self::UnprocessableEntity(format!("email {} already exists", email))
            }
            UpdateUserError::NotFoundUser { id } => {
                Self::NotFound(format!("user id {} not found", id))
            }
            UpdateUserError::Unknown(_cause) => {
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

#[derive(Debug, Clone, Error)]
enum ParseUpdateUserHttpRequestError {
    #[error(transparent)]
    Id(#[from] uuid::Error),
    #[error(transparent)]
    Username(#[from] UsernameInvalidError),
    #[error(transparent)]
    EmailAddress(#[from] EmailAddressInvalidError),
    #[error(transparent)]
    Password(#[from] PasswordInvalidError),
    #[error(transparent)]
    Role(#[from] RoleInvalidError),
}

impl From<ParseUpdateUserHttpRequestError> for ApiError {
    fn from(e: ParseUpdateUserHttpRequestError) -> Self {
        let message = match e {
            ParseUpdateUserHttpRequestError::Id(_cause) => "id is invalid".to_string(),
            ParseUpdateUserHttpRequestError::Username(cause) => {
                format!("username '{}' is invalid", cause.username)
            }
            ParseUpdateUserHttpRequestError::EmailAddress(cause) => {
                format!("email address '{}' is invalid", cause.email)
            }
            ParseUpdateUserHttpRequestError::Password(_cause) => "password is invalid".to_string(),
            ParseUpdateUserHttpRequestError::Role(cause) => {
                format!("role '{}' is invalid", cause.role)
            }
        };

        Self::UnprocessableEntity(message)
    }
}

/// The body of a [User] update request.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub struct UpdateUserHttpRequestBody {
    username: String,
    email: String,
    password: String,
    role: String,
}

impl UpdateUserHttpRequestBody {
    fn try_into_domain(
        self,
        id: uuid::Uuid,
    ) -> Result<UpdateUserInput, ParseUpdateUserHttpRequestError> {
        let name = Username::new(&self.username)?;
        let email = EmailAddress::new(&self.email)?;
        let password = Password::new(&self.password)?;
        let role = Role::new(&self.role)?;
        Ok(UpdateUserInput::new(id, name, email, password, role))
    }
}

/// The response body data field for successful [User] update.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct UpdateUserResponse {
    id: String,
}

impl From<&UpdateUserOutput> for UpdateUserResponse {
    fn from(output: &UpdateUserOutput) -> Self {
        Self {
            id: output.id.to_string(),
        }
    }
}

pub async fn update_user<US: UserService>(
    Path(id): Path<String>,
    State(state): State<AppState<US>>,
    Json(body): Json<UpdateUserHttpRequestBody>,
) -> Result<ApiSuccess<UpdateUserResponse>, ApiError> {
    let uuid = uuid::Uuid::parse_str(&id).map_err(ParseUpdateUserHttpRequestError::from)?;
    let domain_req = body.try_into_domain(uuid)?;

    state
        .user_service
        .update_user(&domain_req)
        .await
        .map_err(ApiError::from)
        .map(|ref output| ApiSuccess::new(StatusCode::OK, output.into()))
}
