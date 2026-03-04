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

#[derive(Debug, Clone)]
pub struct ApiSuccess<T: Serialize + PartialEq>(StatusCode, Json<ApiResponseBody<T>>);

impl<T> PartialEq for ApiSuccess<T>
where
    T: Serialize + PartialEq,
{
    fn eq(&self, other: &Self) -> bool {
        self.0 == other.0 && self.1.0 == other.1.0
    }
}

impl<T: Serialize + PartialEq> ApiSuccess<T> {
    fn new(status: StatusCode, data: T) -> Self {
        ApiSuccess(status, Json(ApiResponseBody::new(status, data)))
    }
}

impl<T: Serialize + PartialEq> IntoResponse for ApiSuccess<T> {
    fn into_response(self) -> Response {
        (self.0, self.1).into_response()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ApiError {
    InternalServerError(String),
    NotFound(String),
    UnprocessableEntity(String),
}

impl From<anyhow::Error> for ApiError {
    fn from(e: anyhow::Error) -> Self {
        Self::InternalServerError(e.to_string())
    }
}

impl From<CreateUserError> for ApiError {
    fn from(e: CreateUserError) -> Self {
        match e {
            CreateUserError::DuplicateEmail { email } => {
                Self::UnprocessableEntity(format!("email {} already exists", email))
            }
            CreateUserError::NotFoundUser { id } => {
                Self::NotFound(format!("user id {} not found", id))
            }
            CreateUserError::Unknown(_cause) => {
                // tracing::error!("{:?}\n{}", cause, cause.backtrace());
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
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
                format!("password is invalid")
            }
            ParseCreateUserHttpRequestError::Role(cause) => {
                format!("role '{}' is invalid", cause.role)
            }
        };

        Self::UnprocessableEntity(message)
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        use ApiError::*;

        match self {
            InternalServerError(_e) => {
                // tracing::error!("{}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiResponseBody::new_error(
                        StatusCode::INTERNAL_SERVER_ERROR,
                        "Internal server error".to_string(),
                    )),
                )
                    .into_response()
            }
            UnprocessableEntity(message) => (
                StatusCode::UNPROCESSABLE_ENTITY,
                Json(ApiResponseBody::new_error(
                    StatusCode::UNPROCESSABLE_ENTITY,
                    message,
                )),
            )
                .into_response(),
            NotFound(message) => (
                StatusCode::NOT_FOUND,
                Json(ApiResponseBody::new_error(StatusCode::NOT_FOUND, message)),
            )
                .into_response(),
        }
    }
}

/// Generic response structure shared by all API responses.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ApiResponseBody<T: Serialize + PartialEq> {
    status_code: u16,
    data: T,
}

impl<T: Serialize + PartialEq> ApiResponseBody<T> {
    pub fn new(status_code: StatusCode, data: T) -> Self {
        Self {
            status_code: status_code.as_u16(),
            data,
        }
    }
}

impl ApiResponseBody<ApiErrorData> {
    pub fn new_error(status_code: StatusCode, message: String) -> Self {
        Self {
            status_code: status_code.as_u16(),
            data: ApiErrorData { message },
        }
    }
}

/// The response data format for all error responses.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct ApiErrorData {
    pub message: String,
}

/// The body of an [User] creation request.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub struct CreateUserHttpRequestBody {
    username: String,
    email: String,
    password: String,
    role: String,
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
