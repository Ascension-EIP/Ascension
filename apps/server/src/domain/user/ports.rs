use async_trait::async_trait;
use thiserror::Error;
use uuid::Uuid;

use crate::domain::user::models::user::{
    CreateUserError, CreateUserInput, CreateUserOutput, DeleteUserError, DeleteUserInput,
    EmailAddress, GetUserError, GetUserInput, GetUserOutput, ListUsersError, ListUsersInput,
    ListUsersOutput, Password, Role, UpdateUserError, UpdateUserInput, UpdateUserOutput, Username,
};

/// `UserService` is the public API for the user domain.
///
/// External modules must conform to this contract – the domain is not concerned with the
/// implementation details or underlying technology of any external code.
#[async_trait]
pub trait UserService: Send + Sync + 'static {
    /// Asynchronously create a new [User].
    ///
    /// # Errors
    ///
    /// - [CreateUserError::DuplicateEmail] if an [User] with the same [EmailAddress] already
    /// exists.
    async fn create_user(
        &self,
        req: &CreateUserInput,
    ) -> Result<CreateUserOutput, CreateUserError>;

    async fn list_users(
        &self,
        req: &ListUsersInput,
    ) -> Result<ListUsersOutput, ListUsersError>;

    async fn get_user(
        &self,
        req: &GetUserInput,
    ) -> Result<GetUserOutput, GetUserError>;

    async fn update_user(
        &self,
        req: &UpdateUserInput,
    ) -> Result<UpdateUserOutput, UpdateUserError>;

    async fn delete_user(
        &self,
        req: &DeleteUserInput,
    ) -> Result<(), DeleteUserError>;
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct CreateUserData {
    pub username: Username,
    pub email: EmailAddress,
    pub password_hash: Password,
    pub role: Role,
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ListUsersData {
    pub page: Option<usize>,
    pub per_page: Option<usize>,
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct GetUserData {
    pub id: Uuid,
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
    /// - MUST return [UserRepositoryError::DuplicateEmail] if an [User] with the same
    ///   [EmailAddress] already exists.
    fn create_user(
        &self,
        req: &CreateUserData,
    ) -> impl Future<Output = Result<CreateUserOutput, UserRepositoryError>> + Send;

    /// Get a list of [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::Unknown] if an error occurs.
    fn list_users(
        &self,
        req: &ListUsersData,
    ) -> impl Future<Output = Result<ListUsersOutput, UserRepositoryError>> + Send;

    /// Get a [User] by their unique identifier.
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::NotFoundId] if no [User] with the given id exists.
    fn get_user(
        &self,
        req: &GetUserData,
    ) -> impl Future<Output = Result<GetUserOutput, UserRepositoryError>> + Send;

    /// Update an existing [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::NotFoundId] if no [User] with the given id exists.
    /// - MUST return [UserRepositoryError::DuplicateEmail] if an [User] with the same
    ///   [EmailAddress] already exists.
    fn update_user(
        &self,
        req: &UpdateUserData,
    ) -> impl Future<Output = Result<UpdateUserOutput, UserRepositoryError>> + Send;

    /// Delete an existing [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::NotFoundId] if no [User] with the given id exists.
    fn delete_user(
        &self,
        req: &DeleteUserData,
    ) -> impl Future<Output = Result<(), UserRepositoryError>> + Send;
}
