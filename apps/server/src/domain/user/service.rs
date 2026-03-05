use crate::domain::user::models::user::{
    CreateUserError, CreateUserInput, CreateUserOutput, DeleteUserError, DeleteUserInput,
    GetUserError, GetUserInput, GetUserOutput, ListUsersError, ListUsersInput, ListUsersOutput,
    UpdateUserError, UpdateUserInput, UpdateUserOutput,
};
use crate::domain::user::ports::{
    CreateUserData, DeleteUserData, GetUserData, ListUsersData, UpdateUserData, UserRepository,
    UserService,
};

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

    async fn list_users(&self, input: &ListUsersInput) -> Result<ListUsersOutput, ListUsersError> {
        let list_info = ListUsersData {
            page: input.page,
            per_page: input.per_page,
        };
        let user_list = self.repo.list_users(&list_info).await?;
        Ok(ListUsersOutput::new(user_list.users))
    }

    async fn get_user(&self, input: &GetUserInput) -> Result<GetUserOutput, GetUserError> {
        let get_info = GetUserData { id: input.id };
        let user = self.repo.get_user(&get_info).await?;
        Ok(GetUserOutput::new(
            user.id,
            user.username,
            user.email,
            user.role,
        ))
    }

    async fn update_user(
        &self,
        input: &UpdateUserInput,
    ) -> Result<UpdateUserOutput, UpdateUserError> {
        let update_info = UpdateUserData {
            id: input.id,
            username: input.username.clone(),
            email: input.email.clone(),
            password_hash: input.password.clone(),
            role: input.role.clone(),
        };
        let user = self.repo.update_user(&update_info).await?;
        Ok(UpdateUserOutput::new(user.id))
    }

    async fn delete_user(&self, input: &DeleteUserInput) -> Result<(), DeleteUserError> {
        let delete_info = DeleteUserData { id: input.id };
        self.repo.delete_user(&delete_info).await?;
        Ok(())
    }
}
