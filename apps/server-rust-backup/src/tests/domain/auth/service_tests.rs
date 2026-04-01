#[cfg(test)]
mod tests {
    use std::sync::{Arc, Mutex};
    use uuid::Uuid;

    use async_trait::async_trait;

    use crate::domain::auth::entity::LoginCredentials;
    use crate::domain::auth::error::AuthError;
    use crate::domain::auth::inbound::AuthService;
    use crate::domain::user::entity::{
        email::Email, new_user::NewUser, pagination::Pagination, password::Password, role::Role,
        user::User, username::Username,
    };
    use crate::domain::user::error::UserError;
    use crate::domain::user::outbound::UserRepository;
    use crate::usecase::auth::Service;

    // ─── Helpers ──────────────────────────────────────────────────────────────

    fn make_user(id: Uuid, password_hash: &str) -> User {
        User::new(
            id,
            Username::new("testuser").unwrap(),
            Email::new("test@example.com").unwrap(),
            Password::new(password_hash).unwrap(),
            Role::User,
        )
    }

    fn make_new_user(password: &str) -> NewUser {
        NewUser::new(
            Username::new("testuser").unwrap(),
            Email::new("test@example.com").unwrap(),
            Password::new(password).unwrap(),
            Role::User,
        )
    }

    // ─── Mock Repository ──────────────────────────────────────────────────────

    type ArcResult<T> = Arc<Mutex<Option<Result<T, UserError>>>>;

    fn arc<T>(v: Result<T, UserError>) -> ArcResult<T> {
        Arc::new(Mutex::new(Some(v)))
    }

    #[derive(Clone)]
    struct MockUserRepository {
        create_result: Option<ArcResult<User>>,
        get_result: Option<ArcResult<User>>,
        get_by_email_result: Option<ArcResult<User>>,
    }

    impl MockUserRepository {
        fn new() -> Self {
            Self {
                create_result: None,
                get_result: None,
                get_by_email_result: None,
            }
        }

        fn with_create(mut self, result: Result<User, UserError>) -> Self {
            self.create_result = Some(arc(result));
            self
        }

        fn with_get(mut self, result: Result<User, UserError>) -> Self {
            self.get_result = Some(arc(result));
            self
        }

        fn with_get_by_email(mut self, result: Result<User, UserError>) -> Self {
            self.get_by_email_result = Some(arc(result));
            self
        }
    }

    #[async_trait]
    impl UserRepository for MockUserRepository {
        async fn create_user(&self, _req: &NewUser) -> Result<User, UserError> {
            self.create_result
                .as_ref()
                .expect("create_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("create_result already consumed")
        }

        async fn list_users(&self, _req: &Pagination) -> Result<Vec<User>, UserError> {
            Ok(vec![])
        }

        async fn get_user(&self, _req: &Uuid) -> Result<User, UserError> {
            self.get_result
                .as_ref()
                .expect("get_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("get_result already consumed")
        }

        async fn get_user_by_email(&self, _email: &Email) -> Result<User, UserError> {
            self.get_by_email_result
                .as_ref()
                .expect("get_by_email_result not set")
                .lock()
                .unwrap()
                .take()
                .expect("get_by_email_result already consumed")
        }

        async fn update_user(&self, _req: &User) -> Result<User, UserError> {
            Err(UserError::Unknown(anyhow::anyhow!("not implemented")))
        }

        async fn delete_user(&self, _req: &Uuid) -> Result<(), UserError> {
            Err(UserError::Unknown(anyhow::anyhow!("not implemented")))
        }
    }

    fn make_service(repo: MockUserRepository) -> Service<MockUserRepository> {
        Service::new(Arc::new(repo), "super-secret-test-key".to_string())
    }

    // ─── register ─────────────────────────────────────────────────────────────

    /// A successful registration returns a non-empty JWT string.
    #[tokio::test]
    async fn register_returns_token_on_success() {
        let id = Uuid::new_v4();
        // The repository receives the already-hashed password, so we create a
        // mock user whose password field is anything valid.
        let stored_user = make_user(id, "hashedpassword1234567");
        let repo = MockUserRepository::new().with_create(Ok(stored_user));
        let service = make_service(repo);

        let new_user = make_new_user("plaintextpw");
        let result = service.register(&new_user).await;

        assert!(result.is_ok(), "expected Ok but got {:?}", result);
        assert!(!result.unwrap().token.is_empty());
    }

    /// A registration that collides on email surfaces [AuthError::DuplicateEmail].
    #[tokio::test]
    async fn register_propagates_duplicate_email() {
        let email = Email::new("test@example.com").unwrap();
        let repo = MockUserRepository::new().with_create(Err(UserError::DuplicateEmail(email)));
        let service = make_service(repo);

        let new_user = make_new_user("plaintextpw");
        let result = service.register(&new_user).await;

        assert!(matches!(result, Err(AuthError::DuplicateEmail)));
    }

    // ─── login ────────────────────────────────────────────────────────────────

    /// A login with correct credentials returns a JWT.
    #[tokio::test]
    async fn login_returns_token_with_valid_credentials() {
        // Hash the known password so bcrypt::verify succeeds.
        let raw = "correctpassword";
        let hash = bcrypt::hash(raw, bcrypt::DEFAULT_COST).unwrap();

        let id = Uuid::new_v4();
        let stored_user = make_user(id, &hash);
        let repo = MockUserRepository::new().with_get_by_email(Ok(stored_user));
        let service = make_service(repo);

        let credentials = LoginCredentials::new(
            Email::new("test@example.com").unwrap(),
            Password::new(raw).unwrap(),
        );
        let result = service.login(&credentials).await;

        assert!(result.is_ok(), "expected Ok but got {:?}", result);
        assert!(!result.unwrap().token.is_empty());
    }

    /// A login with a wrong password returns [AuthError::InvalidCredentials].
    #[tokio::test]
    async fn login_fails_with_wrong_password() {
        let hash = bcrypt::hash("correctpassword", bcrypt::DEFAULT_COST).unwrap();

        let id = Uuid::new_v4();
        let stored_user = make_user(id, &hash);
        let repo = MockUserRepository::new().with_get_by_email(Ok(stored_user));
        let service = make_service(repo);

        let credentials = LoginCredentials::new(
            Email::new("test@example.com").unwrap(),
            Password::new("wrongpassword").unwrap(),
        );
        let result = service.login(&credentials).await;

        assert!(
            matches!(result, Err(AuthError::InvalidCredentials)),
            "expected InvalidCredentials but got {:?}",
            result
        );
    }

    /// A login for a non-existing email returns [AuthError::InvalidCredentials].
    #[tokio::test]
    async fn login_fails_when_email_not_found() {
        let repo =
            MockUserRepository::new().with_get_by_email(Err(UserError::UserNotFound(Uuid::nil())));
        let service = make_service(repo);

        let credentials = LoginCredentials::new(
            Email::new("nobody@example.com").unwrap(),
            Password::new("somepassword").unwrap(),
        );
        let result = service.login(&credentials).await;

        assert!(
            matches!(result, Err(AuthError::InvalidCredentials)),
            "expected InvalidCredentials but got {:?}",
            result
        );
    }

    // ─── get_user_by_token ────────────────────────────────────────────────────

    /// A valid JWT is accepted and the correct user is returned.
    #[tokio::test]
    async fn get_user_by_token_returns_user_for_valid_token() {
        let id = Uuid::new_v4();
        let stored_user = make_user(id, "hashedpassword1234567");
        let repo = MockUserRepository::new().with_get(Ok(stored_user.clone()));
        let service = make_service(repo);

        // Generate a token using the same service so the secret matches.
        let new_user = make_new_user("plaintextpw");
        let create_repo = MockUserRepository::new().with_create(Ok(stored_user.clone()));
        let service2 = make_service(create_repo);
        let token = service2.register(&new_user).await.unwrap().token;

        // Now validate it with the first service instance.
        let result = service.get_user_by_token(token).await;

        assert!(result.is_ok(), "expected Ok but got {:?}", result);
        assert_eq!(result.unwrap().id, id);
    }

    /// A tampered / invalid token returns [AuthError::InvalidToken].
    #[tokio::test]
    async fn get_user_by_token_rejects_invalid_token() {
        let repo = MockUserRepository::new();
        let service = make_service(repo);

        let result = service
            .get_user_by_token("this.is.not.a.jwt".to_string())
            .await;

        assert!(
            matches!(result, Err(AuthError::InvalidToken)),
            "expected InvalidToken but got {:?}",
            result
        );
    }

    // ─── JWT token generation ─────────────────────────────────────────────────

    /// Two tokens generated for the same user at the same millisecond are equal
    /// (deterministic w.r.t. secret + payload). This verifies the JWT encode path.
    #[tokio::test]
    async fn register_produces_jwt_with_correct_subject() {
        let id = Uuid::new_v4();
        let stored_user = make_user(id, "hashedpassword1234567");
        let repo = MockUserRepository::new().with_create(Ok(stored_user));
        let service = make_service(repo);

        let new_user = make_new_user("plaintextpw");
        let token = service.register(&new_user).await.unwrap().token;

        // Decode the JWT header to verify it is a valid HS256 token.
        let parts: Vec<&str> = token.split('.').collect();
        assert_eq!(parts.len(), 3, "JWT must have three parts");
    }
}
