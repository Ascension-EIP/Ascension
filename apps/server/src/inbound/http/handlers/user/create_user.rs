use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde::{Deserialize, Serialize};

use crate::domain::user::models::user::{
    CreateUserError, CreateUserInput, CreateUserOutput, EmailAddress, EmailAddressInvalidError,
    Password, PasswordInvalidError, Role, RoleInvalidError, Username, UsernameInvalidError,
};
use crate::domain::user::ports::UserService;
use crate::inbound::http::AppState;
use thiserror::Error;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};

impl From<CreateUserError> for ApiError {
    fn from(e: CreateUserError) -> Self {
        match e {
            CreateUserError::DuplicateEmail { email } => {
                Self::UnprocessableEntity(format!("email {} already exists", email))
            }
            CreateUserError::Unknown(_cause) => {
                // tracing::error!("{:?}\n{}", cause, cause.backtrace());
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

#[derive(Debug, Clone, Error)]
enum ParseCreateUserHttpRequestError {
    #[error(transparent)]
    Username(#[from] UsernameInvalidError),
    #[error(transparent)]
    EmailAddress(#[from] EmailAddressInvalidError),
    #[error(transparent)]
    Password(#[from] PasswordInvalidError),
    #[error(transparent)]
    Role(#[from] RoleInvalidError),
}

impl From<ParseCreateUserHttpRequestError> for ApiError {
    fn from(e: ParseCreateUserHttpRequestError) -> Self {
        let message = match e {
            ParseCreateUserHttpRequestError::Username(cause) => {
                format!("username '{}' is invalid", cause.username)
            }
            ParseCreateUserHttpRequestError::EmailAddress(cause) => {
                format!("email address '{}' is invalid", cause.email)
            }
            ParseCreateUserHttpRequestError::Password(_cause) => {
                "password is invalid".to_string()
            }
            ParseCreateUserHttpRequestError::Role(cause) => {
                format!("role '{}' is invalid", cause.role)
            }
        };

        Self::UnprocessableEntity(message)
    }
}

/// The body of a [User] creation request.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub struct CreateUserHttpRequestBody {
    username: String,
    email: String,
    password: String,
    role: String,
}

impl CreateUserHttpRequestBody {
    fn try_into_domain(self) -> Result<CreateUserInput, ParseCreateUserHttpRequestError> {
        let name = Username::new(&self.username)?;
        let email = EmailAddress::new(&self.email)?;
        let password = Password::new(&self.password)?;
        let role = Role::new(&self.role)?;
        Ok(CreateUserInput::new(name, email, password, role))
    }
}

/// The response body data field for successful [User] creation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct CreateUserResponse {
    id: String,
}

impl From<&CreateUserOutput> for CreateUserResponse {
    fn from(output: &CreateUserOutput) -> Self {
        Self {
            id: output.id.to_string(),
        }
    }
}

/// Create a new [User].
///
/// # Responses
///
/// - 201 Created: the [User] was successfully created.
/// - 422 Unprocessable entity: An [User] with the same name already exists.
pub async fn create_user<US: UserService>(
    State(state): State<AppState<US>>,
    Json(body): Json<CreateUserHttpRequestBody>,
) -> Result<ApiSuccess<CreateUserResponse>, ApiError> {
    let domain_req = body.try_into_domain()?;
    state
        .user_service
        .create_user(&domain_req)
        .await
        .map_err(ApiError::from)
        .map(|ref output| ApiSuccess::new(StatusCode::CREATED, output.into()))
}
