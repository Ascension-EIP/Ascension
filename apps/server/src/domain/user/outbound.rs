use async_trait::async_trait;
use uuid::Uuid;

use crate::domain::user::{
    entity::{email::Email, new_user::NewUser, pagination::Pagination, user::User},
    error::UserError,
};

/// `UserRepository` represents a store of blog data.
///
/// External modules must conform to this contract – the domain is not concerned with the
/// implementation details or underlying technology of any external code.
#[async_trait]
pub trait UserRepository: Send + Sync {
    /// Asynchronously persist a new [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserRepositoryError::DuplicateEmail] if an [User] with the same
    ///   [EmailAddress] already exists.
    async fn create_user(&self, req: &NewUser) -> Result<User, UserError>;

    /// Get a list of [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserError::Unknown] if an error occurs.
    async fn list_users(&self, req: &Pagination) -> Result<Vec<User>, UserError>;

    /// Get a [User] by their unique identifier.
    ///
    /// # Errors
    ///
    /// - MUST return [UserError::NotFoundId] if no [User] with the given id exists.
    async fn get_user(&self, req: &Uuid) -> Result<User, UserError>;

    /// Get a [User] by their email address. Returns the full row including password_hash.
    ///
    /// # Errors
    ///
    /// - MUST return [UserError::UserNotFound] if no [User] with the given email exists.
    async fn get_user_by_email(&self, email: &Email) -> Result<User, UserError>;

    /// Update an existing [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserError::NotFoundId] if no [User] with the given id exists.
    /// - MUST return [UserError::DuplicateEmail] if an [User] with the same
    ///   [EmailAddress] already exists.
    async fn update_user(&self, req: &User) -> Result<User, UserError>;

    /// Delete an existing [User].
    ///
    /// # Errors
    ///
    /// - MUST return [UserError::NotFoundId] if no [User] with the given id exists.
    async fn delete_user(&self, req: &Uuid) -> Result<(), UserError>;
}
