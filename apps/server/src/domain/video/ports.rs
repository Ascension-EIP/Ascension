use async_trait::async_trait;
use thiserror::Error;
use uuid::Uuid;

use crate::domain::video::models::{CreateVideoInput, CreateVideoOutput, Video};

#[derive(Debug, Error)]
pub enum VideoRepositoryError {
    #[error("video not found: {id}")]
    NotFound { id: Uuid },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

#[async_trait]
pub trait VideoRepository: Send + Sync + 'static {
    async fn create_video(
        &self,
        req: &CreateVideoInput,
    ) -> Result<CreateVideoOutput, VideoRepositoryError>;

    async fn get_video(&self, id: Uuid) -> Result<Video, VideoRepositoryError>;
}

#[derive(Debug, Error)]
pub enum VideoServiceError {
    #[error("video not found: {id}")]
    #[allow(dead_code)]
    NotFound { id: Uuid },
    #[error("presign error: {0}")]
    Presign(String),
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

#[async_trait]
pub trait VideoService: Send + Sync + 'static {
    /// Generate a presigned upload URL and persist the video record.
    async fn get_upload_url(
        &self,
        user_id: Uuid,
        filename: String,
    ) -> Result<(Uuid, String), VideoServiceError>;

    #[allow(dead_code)]
    async fn get_video(&self, id: Uuid) -> Result<Video, VideoServiceError>;
}
