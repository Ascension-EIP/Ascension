use std::future::Future;

use thiserror::Error;
use uuid::Uuid;

use crate::domain::user::models::user::{
    CreateUserError, CreateUserInput, CreateUserOutput, DeleteUserError, DeleteUserInput,
    EmailAddress, GetUserError, GetUserInput, GetUserOutput, ListUsersError, ListUsersInput,
    ListUsersOutput, Password, Role, UpdateUserError, UpdateUserInput, UpdateUserOutput, User,
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

    fn get_user(
        &self,
        id: &GetUserInput,
    ) -> impl Future<Output = Result<GetUserOutput, GetUserError>> + Send;

    fn list_users(
        &self,
        req: &ListUsersInput,
    ) -> impl Future<Output = Result<ListUsersOutput, ListUsersError>> + Send;

    fn update_user(
        &self,
        req: &UpdateUserInput,
    ) -> impl Future<Output = Result<UpdateUserOutput, UpdateUserError>> + Send;

    fn delete_user(
        &self,
        req: &DeleteUserInput,
    ) -> impl Future<Output = Result<(), DeleteUserError>> + Send;
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct CreateUserData {
    pub username: Username,
    pub email: EmailAddress,
    pub password_hash: Password,
    pub role: Role,
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct GetUserData {
    pub id: Uuid,
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ListUsersData {
    pub page: usize,
    pub per_page: usize,
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
    /// [EmailAddress] already exists.
    fn create_user(
        &self,
        req: &CreateUserData,
    ) -> impl Future<Output = Result<User, UserRepositoryError>> + Send;//TODO checkez si c'est bien ça ou si on doit renvoyer un UUID dans le future

    /// Get a [User] by their unique identifier.
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::NotFoundId] if no [User] with the given id exists.
    fn get_user(&self, id: Uuid) -> impl Future<Output = Result<User, UserRepositoryError>> + Send;

    /// Get a list of [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::Unknown] if an error occurs.
    fn list_users(&self) -> impl Future<Output = Result<Vec<User>, UserRepositoryError>> + Send;

    /// Update an existing [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::NotFoundId] if no [User] with the given id exists.
    /// - MUST return [UserRepositoryError::DuplicateEmail] if an [User] with the same
    /// [EmailAddress] already exists.
    fn update_user(
        &self,
        req: &UpdateUserData,
    ) -> impl Future<Output = Result<User, UserRepositoryError>> + Send;

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
