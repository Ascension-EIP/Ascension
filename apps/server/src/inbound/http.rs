use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;

use anyhow::Context;
use axum::Router;
use axum::http::StatusCode;
use axum::routing::{delete, get, post, put};
use tokio::net;
use tower::ServiceBuilder;
use tower_cookies::CookieManagerLayer;
use tower_governor::GovernorLayer;
use tower_governor::governor::GovernorConfigBuilder;
use tower_http::trace::TraceLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use crate::domain::analysis::ports::AnalysisService;
use crate::domain::auth::inbound::AuthService;
use crate::domain::user::inbound::UserService;
use crate::domain::video::ports::VideoService;
use crate::inbound::http::handlers::analysis::create_analysis::{
    create_analysis, CreateAnalysisRequest, CreateAnalysisResponse,
};
use crate::inbound::http::handlers::analysis::get_analysis::{
    get_analysis, GetAnalysisResponse,
};
use crate::inbound::http::handlers::auth::login::{login, LoginRequest, LoginResponse};
use crate::inbound::http::handlers::auth::logout::logout;
use crate::inbound::http::handlers::auth::register::{register, RegisterRequest, RegisterResponse};
use crate::inbound::http::handlers::user::create_user::{
    create_user, CreateUserRequest, CreateUserResponse,
};
use crate::inbound::http::handlers::user::delete_user::delete_user;
use crate::inbound::http::handlers::user::get_user::{get_user, GetUserResponse};
use crate::inbound::http::handlers::user::list_users::{
    list_users, ListUserResponse, ListUsersResponse,
};
use crate::inbound::http::handlers::user::update_user::{
    update_user, UpdateUserRequest, UpdateUserResponse,
};
use crate::inbound::http::handlers::video::get_upload_url::{
    get_upload_url, GetUploadUrlRequest, GetUploadUrlResponse,
};

/// Central OpenAPI document — aggregates all route schemas.
#[derive(OpenApi)]
#[openapi(
    paths(
        handlers::auth::login::login,
        handlers::auth::register::register,
        handlers::auth::logout::logout,
        handlers::user::create_user::create_user,
        handlers::user::list_users::list_users,
        handlers::user::get_user::get_user,
        handlers::user::update_user::update_user,
        handlers::user::delete_user::delete_user,
        handlers::video::get_upload_url::get_upload_url,
        handlers::analysis::create_analysis::create_analysis,
        handlers::analysis::get_analysis::get_analysis,
    ),
    components(schemas(
        LoginRequest, LoginResponse,
        RegisterRequest, RegisterResponse,
        CreateUserRequest, CreateUserResponse,
        ListUserResponse, ListUsersResponse,
        GetUserResponse,
        UpdateUserRequest, UpdateUserResponse,
        GetUploadUrlRequest, GetUploadUrlResponse,
        CreateAnalysisRequest, CreateAnalysisResponse,
        GetAnalysisResponse,
    )),
    tags(
        (name = "Auth",     description = "Authentication — register, login, logout"),
        (name = "Users",    description = "User management (CRUD)"),
        (name = "Videos",   description = "Video upload pre-signed URL"),
        (name = "Analyses", description = "AI pose-analysis jobs"),
    ),
    info(
        title = "Ascension API",
        version = "1.0.0",
        description = "AI-powered climbing coach — backend REST API",
    )
)]
pub struct ApiDoc;

mod handlers;
mod middleware;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpServerConfig<'a> {
    pub port: &'a str,
}

#[derive(Clone)]
pub struct AppState {
    pub user_service: Arc<dyn UserService>,
    pub auth_service: Arc<dyn AuthService>,
    pub video_service: Arc<dyn VideoService>,
    pub analysis_service: Arc<dyn AnalysisService>,
}

pub struct HttpServer {
    router: axum::Router,
    listener: net::TcpListener,
}

impl HttpServer {
    pub async fn new(
        user_service: Arc<dyn UserService>,
        auth_service: Arc<dyn AuthService>,
        video_service: Arc<dyn VideoService>,
        analysis_service: Arc<dyn AnalysisService>,
        config: HttpServerConfig<'_>,
    ) -> anyhow::Result<Self> {
        let state = AppState {
            user_service,
            auth_service,
            video_service,
            analysis_service,
        };

        let strict = Arc::new(
            GovernorConfigBuilder::default()
                .period(Duration::from_secs(1))
                .burst_size(10)
                .finish()
                .context("failed to build rate limiter configuration")?,
        );

        {
            let limiter = strict.limiter();
            let l = limiter.clone();
            tokio::spawn(async move {
                let mut interval = tokio::time::interval(Duration::from_secs(60));
                loop {
                    interval.tick().await;
                    l.retain_recent();
                }
            });
        }

        let router = Router::new()
            .merge(SwaggerUi::new("/swagger-ui").url("/api-docs/openapi.json", ApiDoc::openapi()))
            .route("/", get(|| async { StatusCode::OK }))
            .nest("/v1", v1_routes())
            .layer(
                ServiceBuilder::new()
                    // .layer(RecoveryLayer::new())
                    .layer(TraceLayer::new_for_http())
                    .layer(GovernorLayer::new(strict))
                    // Cookie manager must wrap the entire app so that auth
                    // middleware and handlers can read / write cookies.
                    .layer(CookieManagerLayer::new()),
            )
            .with_state(state);

        let listener = net::TcpListener::bind(format!("0.0.0.0:{}", config.port))
            .await
            .with_context(|| format!("failed to listen on {}", config.port))?;

        Ok(Self { router, listener })
    }

    pub async fn run(self) -> anyhow::Result<()> {
        tracing::info!("listening on {}", self.listener.local_addr().unwrap());
        axum::serve(
            self.listener,
            self.router
                .into_make_service_with_connect_info::<SocketAddr>(),
        )
        .await
        .context("received error from running server")?;
        Ok(())
    }
}

fn v1_routes() -> Router<AppState> {
    Router::new()
        .nest("/auth", v1_auth_routes())
        .nest("/users", v1_users_routes())
        .nest("/videos", v1_videos_routes())
        .nest("/analyses", v1_analyses_routes())
}

fn v1_auth_routes() -> Router<AppState> {
    Router::new()
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/logout", post(logout))
}

fn v1_users_routes() -> Router<AppState> {
    Router::new()
        .route("/", post(create_user))
        .route("/", get(list_users))
        .route("/{id}", get(get_user))
        .route("/{id}", put(update_user))
        .route("/{id}", delete(delete_user))
}

fn v1_videos_routes() -> Router<AppState> {
    Router::new().route("/upload-url", post(get_upload_url))
}

fn v1_analyses_routes() -> Router<AppState> {
    Router::new()
        .route("/", post(create_analysis))
        .route("/{id}", get(get_analysis))
}
