use std::sync::Arc;

use anyhow::Context;
use axum::Router;
use axum::routing::{delete, get, post, put};
use tokio::net;

use crate::domain::user::ports::UserService;
use crate::inbound::http::handlers::user::create_user::create_user;
use crate::inbound::http::handlers::user::delete_user::delete_user;
use crate::inbound::http::handlers::user::update_user::update_user;
use crate::inbound::http::handlers::user::get_user::get_user;
use crate::inbound::http::handlers::user::list_users::list_users;
use crate::inbound::http::handlers::status::api_status;

mod handlers;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpServerConfig<'a> {
    pub port: &'a str,
}

#[derive(Debug, Clone)]
struct AppState<US: UserService> {
    user_service: Arc<US>,
}

pub struct HttpServer {
    router: axum::Router,
    listener: net::TcpListener,
}

impl HttpServer {
    pub async fn new(
        user_service: impl UserService,
        config: HttpServerConfig<'_>,
    ) -> anyhow::Result<Self> {
        // let trace_layer = tower_http::trace::TraceLayer::new_for_http().make_span_with(
        //     |request: &axum::extract::Request<_>| {
        //         let uri = request.uri().to_string();
        //         tracing::info_span!("http_request", method = ?request.method(), uri)
        //     },
        // );

        let state = AppState {
            user_service: Arc::new(user_service),
        };

        let router = axum::Router::new()
            .nest("/api", api_routes())
            .route("/", get(api_status))
            // .layer(trace_layer)
            .with_state(state);

        let listener = net::TcpListener::bind(format!("0.0.0.0:{}", config.port))
            .await
            .with_context(|| format!("failed to listen on {}", config.port))?;

        Ok(Self { router, listener })
    }

    pub async fn run(self) -> anyhow::Result<()> {
        // tracing::debug!("listening on {}", self.listener.local_addr().unwrap());
        axum::serve(self.listener, self.router)
            .await
            .context("received error from running server")?;
        Ok(())
    }
}

fn api_routes<US: UserService>() -> Router<AppState<US>> {
    Router::new().route("/users", post(create_user::<US>))
                 .route("/users", get(list_users::<US>))
                 .route("/users/{id}", get(get_user::<US>))
                 .route("/users/{id}", put(update_user::<US>))
                 .route("/users/{id}", delete(delete_user::<US>))
}
