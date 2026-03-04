use regex::Regex;
use std::{str::FromStr, sync::LazyLock};
use uuid::Uuid;

use derive_more::{Display, From, FromStr};
use serde::{Deserialize, Serialize};
use thiserror::Error;

use crate::domain::user::ports::UserRepositoryError;

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct User {
    pub id: Uuid,
    pub username: Username,
    pub email: EmailAddress,
    pub password: Password,
    pub role: Role,
}

impl User {
    pub fn new(
        id: uuid::Uuid,
        username: Username,
        email: EmailAddress,
        password: Password,
        role: Role,
    ) -> Self {
        Self {
            id,
            username,
            email,
            password,
            role,
        }
    }
}

#[derive(Clone, Display, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Username(String);

#[derive(Clone, Debug, Error)]
#[error("{username} is not a valid username")]
pub struct UsernameInvalidError {
    pub username: String,
}

static USERNAME_RE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^[a-zA-Z0-9_]{8,24}$").unwrap());

impl Username {
    pub fn new(raw: &str) -> Result<Self, UsernameInvalidError> {
        let trimmed = raw.trim();
        if !USERNAME_RE.is_match(trimmed) {
            Err(UsernameInvalidError {
                username: trimmed.to_string(),
            })
        } else {
            Ok(Self(trimmed.to_string()))
        }
    }
}

#[derive(Clone, Display, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct EmailAddress(String);

#[derive(Clone, Debug, Error)]
#[error("{email} is not a valid email address")]
pub struct EmailAddressInvalidError {
    pub email: String,
}

static EMAIL_RE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").unwrap());

impl EmailAddress {
    pub fn new(raw: &str) -> Result<Self, EmailAddressInvalidError> {
        let trimmed = raw.trim();
        if !EMAIL_RE.is_match(trimmed) {
            Err(EmailAddressInvalidError {
                email: trimmed.to_string(),
            })
        } else {
            Ok(Self(trimmed.to_string()))
        }
    }
}

#[derive(Clone, Display, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Password(String);

#[derive(Clone, Debug, Error)]
#[error("{password} is not a valid password")]
pub struct PasswordInvalidError {
    pub password: String,
}

static PASSWORD_RE: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^[^\s]{8,72}$").unwrap());

impl Password {
    pub fn new(raw: &str) -> Result<Self, PasswordInvalidError> {
        let trimmed = raw.trim();
        if !PASSWORD_RE.is_match(trimmed) {
            Err(PasswordInvalidError {
                password: trimmed.to_string(),
            })
        } else {
            Ok(Self(trimmed.to_string()))
        }
    }
}

#[derive(Clone, Display, Debug, PartialEq, PartialOrd, Eq, Ord, Hash, FromStr)]
pub enum Role {
    // #[display("admin")]
    Admin,
    // #[display("user")]
    User,
}

#[derive(Clone, Debug, Error)]
#[error("{role} is not a valid role")]
pub struct RoleInvalidError {
    pub role: String,
}

impl Role {
    pub fn new(role: &str) -> Result<Self, RoleInvalidError> {
        Role::from_str(role).map_err(|_| RoleInvalidError {
            role: role.to_string(),
        })
    }
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash, From)]
pub struct CreateUserInput {
    pub username: Username,
    pub email: EmailAddress,
    pub password: Password,
    pub role: Role,
}

impl CreateUserInput {
    pub fn new(username: Username, email: EmailAddress, password: Password, role: Role) -> Self {
        Self {
            username,
            email,
            password,
            role,
        }
    }
}

pub struct CreateUserOutput {
    pub id: Uuid,
}

impl CreateUserOutput {
    pub fn new(id: Uuid) -> Self {
        Self { id }
    }
}

#[derive(Debug, Error)]
pub enum CreateUserError {
    #[error("user with email address {email} already exists")]
    DuplicateEmail { email: EmailAddress },
    #[error("user id not found")]
    NotFoundUser { id: Uuid },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}



#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash, From)]
pub struct ListUsersInput {
    pub page: usize,
    pub per_page: usize,
}

impl ListUsersInput {
    pub fn new(page: usize, per_page: usize) -> Self {
        Self { page, per_page }
    }
}

pub struct ListUsersOutput {
    pub users: Vec<User>,
}

impl ListUsersOutput {
    pub fn new(users: Vec<User>) -> Self {
        Self { users }
    }
    pub fn into_users(self) -> Vec<User> {
        self.users
    }
}

#[derive(Debug, Error)]
pub enum ListUsersError {
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

impl From<UserRepositoryError> for ListUsersError {
    fn from(err: UserRepositoryError) -> Self {
        match err {
            UserRepositoryError::Unknown(cause) => Self::Unknown(cause),
            _ => Self::Unknown(anyhow::Error::from(err)),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash, From)]
pub struct GetUserInput {
    pub id: Uuid,
}

impl GetUserInput {
    pub fn new(id: Uuid) -> Self {
        Self { id }
    }
}

pub struct GetUserOutput {
    pub user: User,
}

impl GetUserOutput {
    pub fn new(user: User) -> Self {
        Self { user }
    }
}

#[derive(Debug, Error)]
pub enum GetUserError {
    #[error("user id not found")]
    NotFoundUser { id: Uuid },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

impl From<UserRepositoryError> for GetUserError {
    fn from(err: UserRepositoryError) -> Self {
        match err {
            UserRepositoryError::NotFoundId { id } => Self::NotFoundUser { id },
            UserRepositoryError::Unknown(cause) => Self::Unknown(cause),
            _ => Self::Unknown(anyhow::Error::from(err)),
        }
    }
}


#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash, From)]
pub struct UpdateUserInput {
    pub id: Uuid,
    pub username: Username,
    pub email: EmailAddress,
    pub password: Password,
    pub role: Role,
}

impl UpdateUserInput {
    pub fn new(
        id: Uuid,
        username: Username,
        email: EmailAddress,
        password: Password,
        role: Role,
    ) -> Self {
        Self {
            id,
            username,
            email,
            password,
            role,
        }
    }
}

pub struct UpdateUserOutput {
    pub id: Uuid,
}

impl UpdateUserOutput {
    pub fn new(id: Uuid) -> Self {
        Self { id }
    }
}


#[derive(Debug, Error)]
pub enum UpdateUserError {
    #[error("user with email address {email} already exists")]
    DuplicateEmail { email: EmailAddress },
    #[error("user id not found")]
    NotFoundUser { id: Uuid },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}


impl From<UserRepositoryError> for UpdateUserError {
    fn from(err: UserRepositoryError) -> Self {
        match err {
            UserRepositoryError::DuplicateEmail { email } => Self::DuplicateEmail { email },
            UserRepositoryError::NotFoundId { id } => Self::NotFoundUser { id },
            UserRepositoryError::Unknown(cause) => Self::Unknown(cause),
        }
    }
}
