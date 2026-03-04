use std::future::Future;

use thiserror::Error;
use uuid::Uuid;

#[allow(unused_imports)] // Used in comment docs
use crate::domain::user::models::user::{
    CreateUserError, CreateUserInput, CreateUserOutput, EmailAddress, Password, Role, User,
    Username,
};

/// `UserService` is the public API for the user domain.
///
/// External modules must conform to this contract – the domain is not concerned with the
/// implementation details or underlying technology of any external code.
pub trait UserService: Clone + Send + Sync + 'static {
    /// Asynchronously create a new [User].
    ///
    /// # Errors
    ///
    /// - [CreateUserError::DuplicateEmail] if an [User] with the same [EmailAddress] already
    /// exists.
    fn create_user(
        &self,
        req: &CreateUserInput,
    ) -> impl Future<Output = Result<CreateUserOutput, CreateUserError>> + Send;
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct CreateUserData {
    pub username: Username,
    pub email: EmailAddress,
    pub password_hash: Password,
    pub role: Role,
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct UpdateUserData {
    pub id: Uuid,
    pub username: Username,
    pub email: EmailAddress,
    pub password_hash: Password,
    pub role: Role,
}

pub struct DeleteUserData {
    pub id: Uuid,
}

#[derive(Debug, Error)]
pub enum UserRepositoryError {
    #[error("email address {email} already exists")]
    DuplicateEmail { email: EmailAddress },
    #[error("id {id} not found")]
    NotFoundId { id: Uuid },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

/// `UserRepository` represents a store of blog data.
///
/// External modules must conform to this contract – the domain is not concerned with the
/// implementation details or underlying technology of any external code.
pub trait UserRepository: Clone + Send + Sync + 'static {
    /// Asynchronously persist a new [User].
    ///
    /// # Errors
    ///
    /// - MUST return [CreateUserError::DuplicateEmail] if an [User] with the same [EmailAddress]
    /// already exists.
    fn create_user(
        &self,
        req: &CreateUserData,
    ) -> impl Future<Output = Result<User, UserRepositoryError>> + Send;

    /// Asynchronously persist a new [User].
    ///
    /// # Errors
    ///
    /// - MUST return [CreateUserError::DuplicateEmail] if an [User] with the same [EmailAddress]
    /// already exists.
    fn list_users(&self) -> impl Future<Output = Result<Vec<User>, UserRepositoryError>> + Send;

    /// Asynchronously persist a new [User].
    ///
    /// # Errors
    ///
    /// - MUST return [CreateUserError::DuplicateEmail] if an [User] with the same [EmailAddress]
    /// already exists.
    fn update_user(
        &self,
        req: &UpdateUserData,
    ) -> impl Future<Output = Result<User, UserRepositoryError>> + Send;

    /// Asynchronously persist a new [User].
    ///
    /// # Errors
    ///
    /// - MUST return [CreateUserError::DuplicateEmail] if an [User] with the same [EmailAddress]
    /// already exists.
    fn delete_user(
        &self,
        req: &DeleteUserData,
    ) -> impl Future<Output = Result<(), UserRepositoryError>> + Send;
}
