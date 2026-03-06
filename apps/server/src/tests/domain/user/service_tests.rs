#[cfg(test)]
mod tests {
    use std::future::Future;
    use std::sync::{Arc, Mutex};
    use uuid::Uuid;

    use crate::domain::user::models::user::{
        CreateUserInput, CreateUserOutput, DeleteUserInput, EmailAddress, GetUserInput,
        GetUserOutput, ListUserOutput, ListUsersInput, ListUsersOutput, Password, Role,
        UpdateUserInput, UpdateUserOutput, Username,
    };
    use crate::domain::user::ports::{
        CreateUserData, DeleteUserData, GetUserData, ListUsersData, UpdateUserData, UserRepository,
        UserRepositoryError,
    };
    use crate::domain::user::service::Service;
    use crate::domain::user::ports::UserService;

    // ─── Mock Repository ──────────────────────────────────────────────────────
    //
    // Results are stored behind Arc<Mutex<Option<...>>> so the mock is Clone
    // without requiring the inner types to implement Clone.

    type ArcResult<T> = Arc<Mutex<Option<Result<T, UserRepositoryError>>>>;

    fn arc<T>(v: Result<T, UserRepositoryError>) -> ArcResult<T> {
        Arc::new(Mutex::new(Some(v)))
    }

    #[derive(Clone)]
    struct MockUserRepository {
        create_result: Option<ArcResult<CreateUserOutput>>,
        list_result: Option<ArcResult<ListUsersOutput>>,
        get_result: Option<ArcResult<GetUserOutput>>,
        update_result: Option<ArcResult<UpdateUserOutput>>,
        delete_result: Option<ArcResult<()>>,
    }

    impl MockUserRepository {
        fn new() -> Self {
            Self {
                create_result: None,
                list_result: None,
                get_result: None,
                update_result: None,
                delete_result: None,
            }
        }

        fn with_create(mut self, result: Result<CreateUserOutput, UserRepositoryError>) -> Self {
            self.create_result = Some(arc(result));
            self
        }

        fn with_list(mut self, result: Result<ListUsersOutput, UserRepositoryError>) -> Self {
            self.list_result = Some(arc(result));
            self
        }

        fn with_get(mut self, result: Result<GetUserOutput, UserRepositoryError>) -> Self {
            self.get_result = Some(arc(result));
            self
        }

        fn with_update(mut self, result: Result<UpdateUserOutput, UserRepositoryError>) -> Self {
            self.update_result = Some(arc(result));
            self
        }

        fn with_delete(mut self, result: Result<(), UserRepositoryError>) -> Self {
            self.delete_result = Some(arc(result));
            self
        }

        fn take_create(&self) -> Result<CreateUserOutput, UserRepositoryError> {
            self.create_result
                .as_ref()
                .expect("create_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("create_result already consumed")
        }

        fn take_list(&self) -> Result<ListUsersOutput, UserRepositoryError> {
            self.list_result
                .as_ref()
                .expect("list_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("list_result already consumed")
        }

        fn take_get(&self) -> Result<GetUserOutput, UserRepositoryError> {
            self.get_result
                .as_ref()
                .expect("get_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("get_result already consumed")
        }

        fn take_update(&self) -> Result<UpdateUserOutput, UserRepositoryError> {
            self.update_result
                .as_ref()
                .expect("update_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("update_result already consumed")
        }

        fn take_delete(&self) -> Result<(), UserRepositoryError> {
            self.delete_result
                .as_ref()
                .expect("delete_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("delete_result already consumed")
        }
    }

    impl UserRepository for MockUserRepository {
        fn create_user(
            &self,
            _req: &CreateUserData,
        ) -> impl Future<Output = Result<CreateUserOutput, UserRepositoryError>> + Send {
            let result = self.take_create();
            async move { result }
        }

        fn list_users(
            &self,
            _req: &ListUsersData,
        ) -> impl Future<Output = Result<ListUsersOutput, UserRepositoryError>> + Send {
            let result = self.take_list();
            async move { result }
        }

        fn get_user(
            &self,
            _req: &GetUserData,
        ) -> impl Future<Output = Result<GetUserOutput, UserRepositoryError>> + Send {
            let result = self.take_get();
            async move { result }
        }

        fn update_user(
            &self,
            _req: &UpdateUserData,
        ) -> impl Future<Output = Result<UpdateUserOutput, UserRepositoryError>> + Send {
            let result = self.take_update();
            async move { result }
        }

        fn delete_user(
            &self,
            _req: &DeleteUserData,
        ) -> impl Future<Output = Result<(), UserRepositoryError>> + Send {
            let result = self.take_delete();
            async move { result }
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    fn valid_username() -> Username {
        Username::new("validuser1").unwrap()
    }

    fn valid_email() -> EmailAddress {
        EmailAddress::new("user@example.com").unwrap()
    }

    fn valid_email_2() -> EmailAddress {
        EmailAddress::new("other@example.com").unwrap()
    }

    fn valid_password() -> Password {
        Password::new("securepassword1!").unwrap()
    }

    fn valid_role() -> Role {
        Role::new("User").unwrap()
    }

    fn fixed_uuid() -> Uuid {
        Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap()
    }

    // ─── create_user ─────────────────────────────────────────────────────────

    #[tokio::test]
    async fn create_user_returns_id_on_success() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new()
            .with_create(Ok(CreateUserOutput::new(id)));
        let service = Service::new(repo);

        let input = CreateUserInput::new(valid_username(), valid_email(), valid_password(), valid_role());
        let result = service.create_user(&input).await;

        assert!(result.is_ok());
        assert_eq!(result.unwrap().id, id);
    }

    #[tokio::test]
    async fn create_user_returns_duplicate_email_error() {
        let email = valid_email();
        let repo = MockUserRepository::new().with_create(Err(
            UserRepositoryError::DuplicateEmail { email: email.clone() },
        ));
        let service = Service::new(repo);

        let input = CreateUserInput::new(valid_username(), email, valid_password(), valid_role());
        let result = service.create_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::CreateUserError::DuplicateEmail { .. })
        );
    }

    #[tokio::test]
    async fn create_user_propagates_unknown_error() {
        let repo = MockUserRepository::new().with_create(Err(UserRepositoryError::Unknown(
            anyhow::anyhow!("database down"),
        )));
        let service = Service::new(repo);

        let input = CreateUserInput::new(valid_username(), valid_email(), valid_password(), valid_role());
        let result = service.create_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::CreateUserError::Unknown(_))
        );
    }

    // ─── list_users ──────────────────────────────────────────────────────────

    #[tokio::test]
    async fn list_users_returns_all_users() {
        let id1 = Uuid::new_v4();
        let id2 = Uuid::new_v4();
        let users = vec![
            ListUserOutput::new(id1, valid_username(), valid_email(), valid_role()),
            ListUserOutput::new(
                id2,
                Username::new("otheruser2").unwrap(),
                valid_email_2(),
                Role::new("Admin").unwrap(),
            ),
        ];
        let repo = MockUserRepository::new().with_list(Ok(ListUsersOutput::new(users)));
        let service = Service::new(repo);

        let input = ListUsersInput::new(None, None);
        let result = service.list_users(&input).await;

        assert!(result.is_ok());
        let output = result.unwrap();
        assert_eq!(output.users.len(), 2);
    }

    #[tokio::test]
    async fn list_users_returns_empty_list_when_no_users() {
        let repo = MockUserRepository::new().with_list(Ok(ListUsersOutput::new(vec![])));
        let service = Service::new(repo);

        let input = ListUsersInput::new(None, None);
        let result = service.list_users(&input).await;

        assert!(result.is_ok());
        assert!(result.unwrap().users.is_empty());
    }

    #[tokio::test]
    async fn list_users_propagates_unknown_error() {
        let repo = MockUserRepository::new().with_list(Err(UserRepositoryError::Unknown(
            anyhow::anyhow!("connection lost"),
        )));
        let service = Service::new(repo);

        let input = ListUsersInput::new(Some(1), Some(10));
        let result = service.list_users(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::ListUsersError::Unknown(_))
        );
    }

    #[tokio::test]
    async fn list_users_with_pagination_parameters_passes_through() {
        let repo = MockUserRepository::new().with_list(Ok(ListUsersOutput::new(vec![])));
        let service = Service::new(repo);

        let input = ListUsersInput::new(Some(2), Some(5));
        let result = service.list_users(&input).await;

        assert!(result.is_ok());
    }

    // ─── get_user ────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn get_user_returns_user_on_success() {
        let id = fixed_uuid();
        let expected = GetUserOutput::new(id, valid_username(), valid_email(), valid_role());
        let repo = MockUserRepository::new().with_get(Ok(expected));
        let service = Service::new(repo);

        let input = GetUserInput::new(id);
        let result = service.get_user(&input).await;

        assert!(result.is_ok());
        let output = result.unwrap();
        assert_eq!(output.id, id);
        assert_eq!(output.username, valid_username());
        assert_eq!(output.email, valid_email());
    }

    #[tokio::test]
    async fn get_user_returns_not_found_error() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new()
            .with_get(Err(UserRepositoryError::NotFoundId { id }));
        let service = Service::new(repo);

        let input = GetUserInput::new(id);
        let result = service.get_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::GetUserError::NotFoundUser { .. })
        );
    }

    #[tokio::test]
    async fn get_user_propagates_unknown_error() {
        let repo = MockUserRepository::new().with_get(Err(UserRepositoryError::Unknown(
            anyhow::anyhow!("query failed"),
        )));
        let service = Service::new(repo);

        let input = GetUserInput::new(fixed_uuid());
        let result = service.get_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::GetUserError::Unknown(_))
        );
    }

    // ─── update_user ─────────────────────────────────────────────────────────

    #[tokio::test]
    async fn update_user_returns_id_on_success() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new().with_update(Ok(UpdateUserOutput::new(id)));
        let service = Service::new(repo);

        let input = UpdateUserInput::new(id, valid_username(), valid_email(), valid_password(), valid_role());
        let result = service.update_user(&input).await;

        assert!(result.is_ok());
        assert_eq!(result.unwrap().id, id);
    }

    #[tokio::test]
    async fn update_user_returns_not_found_error() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new()
            .with_update(Err(UserRepositoryError::NotFoundId { id }));
        let service = Service::new(repo);

        let input = UpdateUserInput::new(id, valid_username(), valid_email(), valid_password(), valid_role());
        let result = service.update_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::UpdateUserError::NotFoundUser { .. })
        );
    }

    #[tokio::test]
    async fn update_user_returns_duplicate_email_error() {
        let id = fixed_uuid();
        let email = valid_email();
        let repo = MockUserRepository::new().with_update(Err(
            UserRepositoryError::DuplicateEmail { email: email.clone() },
        ));
        let service = Service::new(repo);

        let input = UpdateUserInput::new(id, valid_username(), email, valid_password(), valid_role());
        let result = service.update_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::UpdateUserError::DuplicateEmail { .. })
        );
    }

    #[tokio::test]
    async fn update_user_propagates_unknown_error() {
        let repo = MockUserRepository::new().with_update(Err(UserRepositoryError::Unknown(
            anyhow::anyhow!("constraint error"),
        )));
        let service = Service::new(repo);

        let id = fixed_uuid();
        let input = UpdateUserInput::new(id, valid_username(), valid_email(), valid_password(), valid_role());
        let result = service.update_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::UpdateUserError::Unknown(_))
        );
    }

    // ─── delete_user ─────────────────────────────────────────────────────────

    #[tokio::test]
    async fn delete_user_succeeds() {
        let repo = MockUserRepository::new().with_delete(Ok(()));
        let service = Service::new(repo);

        let input = DeleteUserInput::new(fixed_uuid());
        let result = service.delete_user(&input).await;

        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn delete_user_returns_not_found_error() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new()
            .with_delete(Err(UserRepositoryError::NotFoundId { id }));
        let service = Service::new(repo);

        let input = DeleteUserInput::new(id);
        let result = service.delete_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::DeleteUserError::NotFoundUser { .. })
        );
    }

    #[tokio::test]
    async fn delete_user_propagates_unknown_error() {
        let repo = MockUserRepository::new().with_delete(Err(UserRepositoryError::Unknown(
            anyhow::anyhow!("foreign key violation"),
        )));
        let service = Service::new(repo);

        let input = DeleteUserInput::new(fixed_uuid());
        let result = service.delete_user(&input).await;

        assert!(result.is_err());
        assert!(
            matches!(result.err().unwrap(), crate::domain::user::models::user::DeleteUserError::Unknown(_))
        );
    }
}
