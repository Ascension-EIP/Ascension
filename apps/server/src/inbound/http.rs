use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;

use anyhow::Context;
use axum::Router;
use axum::http::StatusCode;
use axum::routing::{delete, get, post, put};
use tokio::net;
use tower::ServiceBuilder;
use tower_governor::GovernorLayer;
use tower_governor::governor::GovernorConfigBuilder;
use tower_http::trace::TraceLayer;

use crate::domain::auth::inbound::AuthService;
use crate::domain::user::inbound::UserService;
use crate::inbound::http::handlers::user::create_user::create_user;
use crate::inbound::http::handlers::user::delete_user::delete_user;
use crate::inbound::http::handlers::user::get_user::get_user;
use crate::inbound::http::handlers::user::list_users::list_users;
use crate::inbound::http::handlers::user::update_user::update_user;

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
}

pub struct HttpServer {
    router: axum::Router,
    listener: net::TcpListener,
}

impl HttpServer {
    pub async fn new(
        user_service: Arc<dyn UserService>,
        auth_service: Arc<dyn AuthService>,
        config: HttpServerConfig<'_>,
    ) -> anyhow::Result<Self> {
        let state = AppState {
            user_service,
            auth_service,
        };

        let strict = Arc::new(
            GovernorConfigBuilder::default()
                .period(Duration::from_secs(1))
                .burst_size(10)
                .finish()
                .unwrap(),
        );

        for limiter in [strict.limiter()] {
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
            .route(
                "/healthz",
                get(|| async { StatusCode::NO_CONTENT }).route_layer(
                    ServiceBuilder::new()
                        .layer(axum::middleware::from_fn_with_state(
                            state.clone(),
                            middleware::auth::auth,
                        ))
                        .layer(axum::middleware::from_fn_with_state(
                            state.clone(),
                            middleware::auth::admin,
                        )),
                ),
            )
            .nest("/v1", v1_routes())
            .layer(
                ServiceBuilder::new()
                    // .layer(RecoveryLayer::new())
                    .layer(TraceLayer::new_for_http())
                    .layer(GovernorLayer::new(strict)),
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
    Router::new().nest("/users", v1_users_routes())
}

fn v1_users_routes() -> Router<AppState> {
    Router::new()
        .route("/", post(create_user))
        .route("/", get(list_users))
        .route("/{id}", get(get_user))
        .route("/{id}", put(update_user))
        .route("/{id}", delete(delete_user))
}
