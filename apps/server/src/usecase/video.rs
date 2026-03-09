use std::sync::Arc;
use std::time::Duration;

use async_trait::async_trait;
use uuid::Uuid;

use crate::domain::video::models::{CreateVideoInput, Video};
use crate::domain::video::ports::{VideoRepository, VideoService, VideoServiceError};
use crate::outbound::minio::MinioClient;

pub struct VideoServiceImpl<R: VideoRepository> {
    repo: Arc<R>,
    minio: Arc<MinioClient>,
    minio_bucket: String,
}

impl<R: VideoRepository> VideoServiceImpl<R> {
    pub fn new(repo: Arc<R>, minio: Arc<MinioClient>, minio_bucket: String) -> Self {
        Self {
            repo,
            minio,
            minio_bucket,
        }
    }
}

#[async_trait]
impl<R: VideoRepository> VideoService for VideoServiceImpl<R> {
    async fn get_upload_url(
        &self,
        user_id: Uuid,
        filename: String,
    ) -> Result<(Uuid, String), VideoServiceError> {
        // Build a unique object key
        let object_key = format!("{}/{}", user_id, filename);

        // Generate presigned PUT URL (15-minute validity)
        let upload_url = self
            .minio
            .presign_put(&object_key, Duration::from_secs(900))
            .await
            .map_err(|e| VideoServiceError::Presign(e.to_string()))?;

        // Persist the video record
        let input = CreateVideoInput {
            user_id,
            object_key,
            bucket: self.minio_bucket.clone(),
            filename,
        };
        let out = self
            .repo
            .create_video(&input)
            .await
            .map_err(|e| VideoServiceError::Unknown(anyhow::anyhow!(e.to_string())))?;

        Ok((out.id, upload_url))
    }

    async fn get_video(&self, id: Uuid) -> Result<Video, VideoServiceError> {
        self.repo.get_video(id).await.map_err(|e| {
            use crate::domain::video::ports::VideoRepositoryError;
            match e {
                VideoRepositoryError::NotFound { id } => VideoServiceError::NotFound { id },
                VideoRepositoryError::Unknown(cause) => VideoServiceError::Unknown(cause),
            }
        })
    }
}
