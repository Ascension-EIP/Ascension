use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use utoipa::ToSchema;

use crate::domain::analysis::ports::AnalysisServiceError;
use crate::inbound::http::AppState;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};

impl From<AnalysisServiceError> for ApiError {
    fn from(e: AnalysisServiceError) -> Self {
        match e {
            AnalysisServiceError::NotFound { id } => {
                Self::NotFound(format!("analysis {} not found", id))
            }
            AnalysisServiceError::VideoNotFound { id } => {
                Self::NotFound(format!("video {} not found", id))
            }
            AnalysisServiceError::Queue(msg) => Self::InternalServerError(msg),
            AnalysisServiceError::Unknown(cause) => {
                tracing::error!("{:?}", cause);
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct CreateAnalysisRequest {
    pub video_id: Uuid,
}

#[derive(Debug, Serialize, PartialEq, Eq, ToSchema)]
pub struct CreateAnalysisResponse {
    pub analysis_id: Uuid,
    pub job_id: Uuid,
    /// Always `"pending"` at creation time
    pub status: String,
}

/// Trigger a pose-analysis job for a video.
///
/// Publishes a job to the `vision.skeleton` RabbitMQ queue.
/// Poll `GET /v1/analyses/{id}` to check completion.
#[utoipa::path(
    post,
    path = "/v1/analyses",
    request_body = CreateAnalysisRequest,
    responses(
        (status = 202, description = "Job queued", body = CreateAnalysisResponse),
        (status = 404, description = "video_id does not exist"),
        (status = 500, description = "RabbitMQ publish failed"),
    ),
    tag = "Analyses"
)]
pub async fn create_analysis(
    State(state): State<AppState>,
    Json(body): Json<CreateAnalysisRequest>,
) -> Result<ApiSuccess<CreateAnalysisResponse>, ApiError> {
    let analysis = state
        .analysis_service
        .trigger_analysis(body.video_id)
        .await?;

    Ok(ApiSuccess::new(
        StatusCode::ACCEPTED,
        CreateAnalysisResponse {
            analysis_id: analysis.id,
            job_id: analysis.job_id,
            status: analysis.status,
        },
    ))
}
