use std::sync::Arc;

use async_trait::async_trait;
use uuid::Uuid;

use crate::domain::user::entity::{new_user::NewUser, pagination::Pagination, user::User};
use crate::domain::user::error::UserError;
use crate::domain::user::inbound::UserService;
use crate::domain::user::outbound::UserRepository;

#[derive(Debug, Clone)]
pub struct Service<R>
where
    R: UserRepository,
{
    repo: Arc<R>,
}

impl<R> Service<R>
where
    R: UserRepository,
{
    pub fn new(repo: Arc<R>) -> Self {
        Self { repo }
    }
}

#[async_trait]
impl<R> UserService for Service<R>
where
    R: UserRepository,
{
    /// Create the [User] specified in input [CreateUserInput]
    ///
    /// # Errors
    ///
    /// - Return an [CreateUserError].
    async fn create_user(&self, user: &NewUser) -> Result<User, UserError> {
        let user = self.repo.create_user(user).await?;
        Ok(user)
    }

    async fn list_users(&self, params: &Pagination) -> Result<Vec<User>, UserError> {
        let user_list = self.repo.list_users(params).await?;
        Ok(user_list)
    }

    async fn get_user(&self, id: &Uuid) -> Result<User, UserError> {
        let user = self.repo.get_user(id).await?;
        Ok(user)
    }

    async fn update_user(&self, user: &User) -> Result<User, UserError> {
        let user = self.repo.update_user(user).await?;
        Ok(user)
    }

    async fn delete_user(&self, id: &Uuid) -> Result<(), UserError> {
        self.repo.delete_user(id).await?;
        Ok(())
    }
}
