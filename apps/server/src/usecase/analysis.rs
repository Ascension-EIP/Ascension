use std::sync::Arc;

use async_trait::async_trait;
use serde::Serialize;
use uuid::Uuid;

use crate::domain::analysis::models::{Analysis, CreateAnalysisInput};
use crate::domain::analysis::ports::{AnalysisRepository, AnalysisService, AnalysisServiceError};
use crate::domain::video::ports::VideoRepository;
use crate::outbound::rabbitmq::RabbitMqPublisher;

#[derive(Debug, Serialize)]
struct AnalysisJob {
    job_id: String,
    analysis_id: String,
    video_url: String,
}

pub struct AnalysisServiceImpl<A: AnalysisRepository, V: VideoRepository> {
    analysis_repo: Arc<A>,
    video_repo: Arc<V>,
    mq: Arc<RabbitMqPublisher>,
    #[allow(dead_code)]
    minio_bucket: String,
}

impl<A: AnalysisRepository, V: VideoRepository> AnalysisServiceImpl<A, V> {
    pub fn new(
        analysis_repo: Arc<A>,
        video_repo: Arc<V>,
        mq: Arc<RabbitMqPublisher>,
        minio_bucket: String,
    ) -> Self {
        Self {
            analysis_repo,
            video_repo,
            mq,
            minio_bucket,
        }
    }
}

#[async_trait]
impl<A: AnalysisRepository, V: VideoRepository> AnalysisService for AnalysisServiceImpl<A, V> {
    async fn trigger_analysis(&self, video_id: Uuid) -> Result<Analysis, AnalysisServiceError> {
        // Make sure the video exists
        let video = self.video_repo.get_video(video_id).await.map_err(|e| {
            use crate::domain::video::ports::VideoRepositoryError;
            match e {
                VideoRepositoryError::NotFound { id } => AnalysisServiceError::VideoNotFound { id },
                VideoRepositoryError::Unknown(cause) => AnalysisServiceError::Unknown(cause),
            }
        })?;

        let job_id = Uuid::new_v4();

        // Persist the analysis row (status = pending)
        let out = self
            .analysis_repo
            .create_analysis(&CreateAnalysisInput { video_id, job_id })
            .await
            .map_err(|e| AnalysisServiceError::Unknown(anyhow::anyhow!(e.to_string())))?;

        // Build the s3:// URL that the AI worker expects
        let video_url = format!("s3://{}/{}", video.bucket, video.object_key);

        // Publish the job to RabbitMQ
        let job = AnalysisJob {
            job_id: job_id.to_string(),
            analysis_id: out.id.to_string(),
            video_url,
        };
        self.mq
            .publish_analysis_job(&job)
            .await
            .map_err(|e| AnalysisServiceError::Queue(e.to_string()))?;

        // Return the freshly-created analysis record
        self.analysis_repo
            .get_analysis(out.id)
            .await
            .map_err(|e| AnalysisServiceError::Unknown(anyhow::anyhow!(e.to_string())))
    }

    async fn get_analysis(&self, id: Uuid) -> Result<Analysis, AnalysisServiceError> {
        self.analysis_repo.get_analysis(id).await.map_err(|e| {
            use crate::domain::analysis::ports::AnalysisRepositoryError;
            match e {
                AnalysisRepositoryError::NotFound { id } => AnalysisServiceError::NotFound { id },
                AnalysisRepositoryError::Unknown(cause) => AnalysisServiceError::Unknown(cause),
            }
        })
    }
}
