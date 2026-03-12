use async_trait::async_trait;
use thiserror::Error;
use uuid::Uuid;

use crate::domain::analysis::models::{Analysis, CreateAnalysisInput, CreateAnalysisOutput};

#[derive(Debug, Error)]
pub enum AnalysisRepositoryError {
    #[error("analysis not found: {id}")]
    NotFound { id: Uuid },
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

#[async_trait]
pub trait AnalysisRepository: Send + Sync + 'static {
    async fn create_analysis(
        &self,
        req: &CreateAnalysisInput,
    ) -> Result<CreateAnalysisOutput, AnalysisRepositoryError>;

    async fn get_analysis(&self, id: Uuid) -> Result<Analysis, AnalysisRepositoryError>;

    /// Update only the progress column (0–100), called by the AI worker via HTTP.
    #[allow(dead_code)]
    async fn update_analysis_progress(
        &self,
        id: Uuid,
        progress: i32,
    ) -> Result<(), AnalysisRepositoryError>;
}

#[derive(Debug, Error)]
pub enum AnalysisServiceError {
    #[error("analysis not found: {id}")]
    NotFound { id: Uuid },
    #[error("video not found: {id}")]
    VideoNotFound { id: Uuid },
    #[error("queue error: {0}")]
    Queue(String),
    #[error(transparent)]
    Unknown(#[from] anyhow::Error),
}

#[async_trait]
pub trait AnalysisService: Send + Sync + 'static {
    /// Create an analysis record and publish a job to RabbitMQ.
    async fn trigger_analysis(&self, video_id: Uuid) -> Result<Analysis, AnalysisServiceError>;

    async fn get_analysis(&self, id: Uuid) -> Result<Analysis, AnalysisServiceError>;

    /// Update progress (0–100). Called by the AI worker.
    #[allow(dead_code)]
    async fn update_analysis_progress(
        &self,
        id: Uuid,
        progress: i32,
    ) -> Result<(), AnalysisServiceError>;
}
