use async_trait::async_trait;
use uuid::Uuid;

use crate::domain::user::{
    entity::{new_user::NewUser, pagination::Pagination, user::User},
    error::UserError,
};

/// `UserService` is the public API for the user domain.
///
/// External modules must conform to this contract – the domain is not concerned with the
/// implementation details or underlying technology of any external code.
#[async_trait]
pub trait UserService: Send + Sync {
    /// Asynchronously create a new [User].
    ///
    /// # Errors
    ///
    /// - [CreateUserError::DuplicateEmail] if an [User] with the same [EmailAddress] already
    /// exists.
    async fn create_user(&self, user: &NewUser) -> Result<User, UserError>;

    async fn list_users(&self, params: &Pagination) -> Result<Vec<User>, UserError>;

    async fn get_user(&self, id: &Uuid) -> Result<User, UserError>;

    async fn update_user(&self, user: &User) -> Result<User, UserError>;

    async fn delete_user(&self, id: &Uuid) -> Result<(), UserError>;
}
