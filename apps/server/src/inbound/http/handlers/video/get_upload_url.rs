use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use utoipa::ToSchema;

use crate::domain::video::ports::VideoServiceError;
use crate::inbound::http::AppState;
use crate::inbound::http::handlers::api::{ApiError, ApiSuccess};

impl From<VideoServiceError> for ApiError {
    fn from(e: VideoServiceError) -> Self {
        match e {
            VideoServiceError::NotFound { id } => Self::NotFound(format!("video {} not found", id)),
            VideoServiceError::Presign(msg) => Self::InternalServerError(msg),
            VideoServiceError::Unknown(cause) => {
                tracing::error!("{:?}", cause);
                Self::InternalServerError("Internal server error".to_string())
            }
        }
    }
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct GetUploadUrlRequest {
    /// Original filename of the video, e.g. "climb.mp4"
    #[schema(example = "my-climb.mp4")]
    pub filename: String,
    /// The user ID requesting the upload (temporary — will come from JWT)
    pub user_id: Uuid,
}

#[derive(Debug, Serialize, PartialEq, Eq, ToSchema)]
pub struct GetUploadUrlResponse {
    /// The UUID of the video record created in the database.
    pub video_id: Uuid,
    /// The presigned PUT URL to upload the video directly to MinIO.
    pub upload_url: String,
}

/// Request a presigned upload URL for a video.
///
/// Returns a pre-signed PUT URL. The client uploads the video directly to MinIO
/// using this URL, then calls `POST /v1/analyses` to trigger processing.
#[utoipa::path(
    post,
    path = "/v1/videos/upload-url",
    request_body = GetUploadUrlRequest,
    responses(
        (status = 201, description = "Upload URL generated", body = GetUploadUrlResponse),
        (status = 500, description = "MinIO presign failed"),
    ),
    tag = "Videos"
)]
pub async fn get_upload_url(
    State(state): State<AppState>,
    Json(body): Json<GetUploadUrlRequest>,
) -> Result<ApiSuccess<GetUploadUrlResponse>, ApiError> {
    let (video_id, upload_url) = state
        .video_service
        .get_upload_url(body.user_id, body.filename)
        .await?;

    Ok(ApiSuccess::new(
        StatusCode::CREATED,
        GetUploadUrlResponse {
            video_id,
            upload_url,
        },
    ))
}
