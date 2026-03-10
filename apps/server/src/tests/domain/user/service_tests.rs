#[cfg(test)]
mod tests {
    use std::sync::{Arc, Mutex};
    use uuid::Uuid;

    use crate::domain::user::entity::{
        email::Email, new_user::NewUser, pagination::Pagination, password::Password, role::Role,
        user::User, username::Username,
    };
    use crate::domain::user::error::UserError;
    use crate::domain::user::inbound::UserService;
    use crate::domain::user::outbound::UserRepository;
    use crate::usecase::user::Service;
    use async_trait::async_trait;

    // ─── Mock Repository ──────────────────────────────────────────────────────
    //
    // Results are stored behind Arc<Mutex<Option<...>>> so the mock is Clone
    // without requiring the inner types to implement Clone.

    type ArcResult<T> = Arc<Mutex<Option<Result<T, UserError>>>>;

    fn arc<T>(v: Result<T, UserError>) -> ArcResult<T> {
        Arc::new(Mutex::new(Some(v)))
    }

    #[derive(Clone)]
    struct MockUserRepository {
        create_result: Option<ArcResult<User>>,
        list_result: Option<ArcResult<Vec<User>>>,
        get_result: Option<ArcResult<User>>,
        update_result: Option<ArcResult<User>>,
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

        fn with_create(mut self, result: Result<User, UserError>) -> Self {
            self.create_result = Some(arc(result));
            self
        }

        fn with_list(mut self, result: Result<Vec<User>, UserError>) -> Self {
            self.list_result = Some(arc(result));
            self
        }

        fn with_get(mut self, result: Result<User, UserError>) -> Self {
            self.get_result = Some(arc(result));
            self
        }

        fn with_update(mut self, result: Result<User, UserError>) -> Self {
            self.update_result = Some(arc(result));
            self
        }

        fn with_delete(mut self, result: Result<(), UserError>) -> Self {
            self.delete_result = Some(arc(result));
            self
        }

        fn take_create(&self) -> Result<User, UserError> {
            self.create_result
                .as_ref()
                .expect("create_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("create_result already consumed")
        }

        fn take_list(&self) -> Result<Vec<User>, UserError> {
            self.list_result
                .as_ref()
                .expect("list_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("list_result already consumed")
        }

        fn take_get(&self) -> Result<User, UserError> {
            self.get_result
                .as_ref()
                .expect("get_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("get_result already consumed")
        }

        fn take_update(&self) -> Result<User, UserError> {
            self.update_result
                .as_ref()
                .expect("update_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("update_result already consumed")
        }

        fn take_delete(&self) -> Result<(), UserError> {
            self.delete_result
                .as_ref()
                .expect("delete_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("delete_result already consumed")
        }
    }

    #[async_trait]
    impl UserRepository for MockUserRepository {
        async fn create_user(&self, _req: &NewUser) -> Result<User, UserError> {
            self.take_create()
        }

        async fn list_users(&self, _req: &Pagination) -> Result<Vec<User>, UserError> {
            self.take_list()
        }

        async fn get_user(&self, _req: &Uuid) -> Result<User, UserError> {
            self.take_get()
        }

        async fn get_user_by_email(&self, _email: &Email) -> Result<User, UserError> {
            Err(UserError::Unknown(anyhow::anyhow!(
                "not implemented in this mock"
            )))
        }

        async fn update_user(&self, _req: &User) -> Result<User, UserError> {
            self.take_update()
        }

        async fn delete_user(&self, _req: &Uuid) -> Result<(), UserError> {
            self.take_delete()
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    fn valid_username() -> Username {
        Username::new("validuser1").unwrap()
    }

    fn valid_email() -> Email {
        Email::new("user@example.com").unwrap()
    }

    fn valid_email_2() -> Email {
        Email::new("other@example.com").unwrap()
    }

    fn make_user(id: Uuid) -> User {
        User::new(
            id,
            valid_username(),
            valid_email(),
            valid_password(),
            valid_role(),
        )
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
        let repo = MockUserRepository::new().with_create(Ok(make_user(id)));
        let service = Service::new(Arc::new(repo));

        let input = NewUser::new(
            valid_username(),
            valid_email(),
            valid_password(),
            valid_role(),
        );
        let result = service.create_user(&input).await;

        assert!(result.is_ok());
        assert_eq!(result.unwrap().id, id);
    }

    #[tokio::test]
    async fn create_user_returns_duplicate_email_error() {
        let email = valid_email();
        let repo =
            MockUserRepository::new().with_create(Err(UserError::DuplicateEmail(email.clone())));
        let service = Service::new(Arc::new(repo));

        let input = NewUser::new(valid_username(), email, valid_password(), valid_role());
        let result = service.create_user(&input).await;

        assert!(result.is_err());
        assert!(matches!(
            result.err().unwrap(),
            UserError::DuplicateEmail(_)
        ));
    }

    #[tokio::test]
    async fn create_user_propagates_unknown_error() {
        let repo = MockUserRepository::new()
            .with_create(Err(UserError::Unknown(anyhow::anyhow!("database down"))));
        let service = Service::new(Arc::new(repo));

        let input = NewUser::new(
            valid_username(),
            valid_email(),
            valid_password(),
            valid_role(),
        );
        let result = service.create_user(&input).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::Unknown(_)));
    }

    // ─── list_users ──────────────────────────────────────────────────────────

    #[tokio::test]
    async fn list_users_returns_all_users() {
        let id1 = Uuid::new_v4();
        let id2 = Uuid::new_v4();
        let users = vec![
            User::new(
                id1,
                valid_username(),
                valid_email(),
                valid_password(),
                valid_role(),
            ),
            User::new(
                id2,
                Username::new("otheruser2").unwrap(),
                valid_email_2(),
                valid_password(),
                Role::new("Admin").unwrap(),
            ),
        ];
        let repo = MockUserRepository::new().with_list(Ok(users));
        let service = Service::new(Arc::new(repo));

        let params = Pagination {
            page: None,
            per_page: None,
        };
        let result = service.list_users(&params).await;

        assert!(result.is_ok());
        let output = result.unwrap();
        assert_eq!(output.len(), 2);
    }

    #[tokio::test]
    async fn list_users_returns_empty_list_when_no_users() {
        let repo = MockUserRepository::new().with_list(Ok(vec![]));
        let service = Service::new(Arc::new(repo));

        let params = Pagination {
            page: None,
            per_page: None,
        };
        let result = service.list_users(&params).await;

        assert!(result.is_ok());
        assert!(result.unwrap().is_empty());
    }

    #[tokio::test]
    async fn list_users_propagates_unknown_error() {
        let repo = MockUserRepository::new()
            .with_list(Err(UserError::Unknown(anyhow::anyhow!("connection lost"))));
        let service = Service::new(Arc::new(repo));

        let params = Pagination {
            page: Some(1),
            per_page: Some(10),
        };
        let result = service.list_users(&params).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::Unknown(_)));
    }

    #[tokio::test]
    async fn list_users_with_pagination_parameters_passes_through() {
        let repo = MockUserRepository::new().with_list(Ok(vec![]));
        let service = Service::new(Arc::new(repo));

        let params = Pagination {
            page: Some(2),
            per_page: Some(5),
        };
        let result = service.list_users(&params).await;

        assert!(result.is_ok());
    }

    // ─── get_user ────────────────────────────────────────────────────────────

    #[tokio::test]
    async fn get_user_returns_user_on_success() {
        let id = fixed_uuid();
        let expected = make_user(id);
        let repo = MockUserRepository::new().with_get(Ok(expected));
        let service = Service::new(Arc::new(repo));

        let result = service.get_user(&id).await;

        assert!(result.is_ok());
        let output = result.unwrap();
        assert_eq!(output.id, id);
        assert_eq!(output.username, valid_username());
        assert_eq!(output.email, valid_email());
    }

    #[tokio::test]
    async fn get_user_returns_not_found_error() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new().with_get(Err(UserError::UserNotFound(id)));
        let service = Service::new(Arc::new(repo));

        let result = service.get_user(&id).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::UserNotFound(_)));
    }

    #[tokio::test]
    async fn get_user_propagates_unknown_error() {
        let repo = MockUserRepository::new()
            .with_get(Err(UserError::Unknown(anyhow::anyhow!("query failed"))));
        let service = Service::new(Arc::new(repo));

        let result = service.get_user(&fixed_uuid()).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::Unknown(_)));
    }

    // ─── update_user ─────────────────────────────────────────────────────────

    #[tokio::test]
    async fn update_user_returns_id_on_success() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new().with_update(Ok(make_user(id)));
        let service = Service::new(Arc::new(repo));

        let user = make_user(id);
        let result = service.update_user(&user).await;

        assert!(result.is_ok());
        assert_eq!(result.unwrap().id, id);
    }

    #[tokio::test]
    async fn update_user_returns_not_found_error() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new().with_update(Err(UserError::UserNotFound(id)));
        let service = Service::new(Arc::new(repo));

        let user = make_user(id);
        let result = service.update_user(&user).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::UserNotFound(_)));
    }

    #[tokio::test]
    async fn update_user_returns_duplicate_email_error() {
        let id = fixed_uuid();
        let email = valid_email();
        let repo =
            MockUserRepository::new().with_update(Err(UserError::DuplicateEmail(email.clone())));
        let service = Service::new(Arc::new(repo));

        let user = make_user(id);
        let result = service.update_user(&user).await;

        assert!(result.is_err());
        assert!(matches!(
            result.err().unwrap(),
            UserError::DuplicateEmail(_)
        ));
    }

    #[tokio::test]
    async fn update_user_propagates_unknown_error() {
        let repo = MockUserRepository::new()
            .with_update(Err(UserError::Unknown(anyhow::anyhow!("constraint error"))));
        let service = Service::new(Arc::new(repo));

        let user = make_user(fixed_uuid());
        let result = service.update_user(&user).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::Unknown(_)));
    }

    // ─── delete_user ─────────────────────────────────────────────────────────

    #[tokio::test]
    async fn delete_user_succeeds() {
        let repo = MockUserRepository::new().with_delete(Ok(()));
        let service = Service::new(Arc::new(repo));

        let result = service.delete_user(&fixed_uuid()).await;

        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn delete_user_returns_not_found_error() {
        let id = fixed_uuid();
        let repo = MockUserRepository::new().with_delete(Err(UserError::UserNotFound(id)));
        let service = Service::new(Arc::new(repo));

        let result = service.delete_user(&id).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::UserNotFound(_)));
    }

    #[tokio::test]
    async fn delete_user_propagates_unknown_error() {
        let repo = MockUserRepository::new().with_delete(Err(UserError::Unknown(anyhow::anyhow!(
            "foreign key violation"
        ))));
        let service = Service::new(Arc::new(repo));

        let result = service.delete_user(&fixed_uuid()).await;

        assert!(result.is_err());
        assert!(matches!(result.err().unwrap(), UserError::Unknown(_)));
    }
}
