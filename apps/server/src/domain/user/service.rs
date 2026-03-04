use crate::domain::user::models::user::{CreateUserError, CreateUserInput, CreateUserOutput};
use crate::domain::user::ports::{CreateUserData, UserRepository, UserService};

#[derive(Debug, Clone)]
pub struct Service<R>
where
    R: UserRepository,
{
    repo: R,
}

impl<R> Service<R>
where
    R: UserRepository,
{
    pub fn new(repo: R) -> Self {
        Self { repo }
    }
}

impl<R> UserService for Service<R>
where
    R: UserRepository,
{
    /// Create the [User] specified in input [CreateUserInput]
    ///
    /// # Errors
    ///
    /// - Return an [CreateUserError].
    async fn create_user(
        &self,
        input: &CreateUserInput,
    ) -> Result<CreateUserOutput, CreateUserError> {
        let user_info = CreateUserData {
            username: input.username.clone(),
            email: input.email.clone(),
            password_hash: input.password.clone(),
            role: input.role.clone(),
        };
        let user = self.repo.create_user(&user_info).await?;
        Ok(CreateUserOutput::new(user.id))
    }
}
