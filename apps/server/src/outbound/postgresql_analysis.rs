use anyhow::anyhow;
use async_trait::async_trait;
use sqlx::Row;
use uuid::Uuid;

use crate::domain::analysis::models::{Analysis, CreateAnalysisInput, CreateAnalysisOutput};
use crate::domain::analysis::ports::{AnalysisRepository, AnalysisRepositoryError};
use crate::domain::video::models::{CreateVideoInput, CreateVideoOutput, Video};
use crate::domain::video::ports::{VideoRepository, VideoRepositoryError};

use crate::outbound::postgresql::Postgres;

// ── Video ─────────────────────────────────────────────────────────────────────

#[async_trait]
impl VideoRepository for Postgres {
    async fn create_video(
        &self,
        req: &CreateVideoInput,
    ) -> Result<CreateVideoOutput, VideoRepositoryError> {
        let id = Uuid::new_v4();
        sqlx::query(
            "INSERT INTO videos (id, user_id, object_key, bucket, filename) VALUES ($1, $2, $3, $4, $5)",
        )
        .bind(id.to_string())
        .bind(req.user_id.to_string())
        .bind(&req.object_key)
        .bind(&req.bucket)
        .bind(&req.filename)
        .execute(&self.pool)
        .await
        .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e).context("failed to insert video")))?;

        Ok(CreateVideoOutput {
            id,
            object_key: req.object_key.clone(),
            bucket: req.bucket.clone(),
        })
    }

    async fn get_video(&self, id: Uuid) -> Result<Video, VideoRepositoryError> {
        let row = sqlx::query(
            "SELECT id, user_id, object_key, bucket, filename, status, created_at FROM videos WHERE id = $1",
        )
        .bind(id.to_string())
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                VideoRepositoryError::NotFound { id }
            } else {
                VideoRepositoryError::Unknown(anyhow!(e).context("failed to get video"))
            }
        })?;

        let raw_id: String = row
            .try_get("id")
            .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?;
        let raw_user_id: String = row
            .try_get("user_id")
            .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?;
        Ok(Video {
            id: Uuid::parse_str(&raw_id).map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?,
            user_id: Uuid::parse_str(&raw_user_id)
                .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?,
            object_key: row
                .try_get("object_key")
                .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?,
            bucket: row
                .try_get("bucket")
                .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?,
            filename: row
                .try_get("filename")
                .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?,
            status: row
                .try_get("status")
                .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?,
            created_at: row
                .try_get("created_at")
                .map_err(|e| VideoRepositoryError::Unknown(anyhow!(e)))?,
        })
    }
}

// ── Analysis ──────────────────────────────────────────────────────────────────

#[async_trait]
impl AnalysisRepository for Postgres {
    async fn create_analysis(
        &self,
        req: &CreateAnalysisInput,
    ) -> Result<CreateAnalysisOutput, AnalysisRepositoryError> {
        let id = Uuid::new_v4();
        sqlx::query(
            "INSERT INTO analyses (id, video_id, job_id, status) VALUES ($1, $2, $3, 'pending')",
        )
        .bind(id.to_string())
        .bind(req.video_id.to_string())
        .bind(req.job_id.to_string())
        .execute(&self.pool)
        .await
        .map_err(|e| {
            AnalysisRepositoryError::Unknown(anyhow!(e).context("failed to insert analysis"))
        })?;

        Ok(CreateAnalysisOutput {
            id,
            job_id: req.job_id,
        })
    }

    async fn get_analysis(&self, id: Uuid) -> Result<Analysis, AnalysisRepositoryError> {
        let row = sqlx::query(
            "SELECT id, video_id, job_id, status, result_json, processing_time_ms, completed_at, created_at FROM analyses WHERE id = $1",
        )
        .bind(id.to_string())
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                AnalysisRepositoryError::NotFound { id }
            } else {
                AnalysisRepositoryError::Unknown(anyhow!(e).context("failed to get analysis"))
            }
        })?;

        let raw_id: String = row
            .try_get("id")
            .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?;
        let raw_video_id: String = row
            .try_get("video_id")
            .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?;
        let raw_job_id: String = row
            .try_get("job_id")
            .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?;
        Ok(Analysis {
            id: Uuid::parse_str(&raw_id)
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
            video_id: Uuid::parse_str(&raw_video_id)
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
            job_id: Uuid::parse_str(&raw_job_id)
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
            status: row
                .try_get("status")
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
            result_json: row
                .try_get("result_json")
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
            processing_time_ms: row
                .try_get("processing_time_ms")
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
            completed_at: row
                .try_get("completed_at")
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
            created_at: row
                .try_get("created_at")
                .map_err(|e| AnalysisRepositoryError::Unknown(anyhow!(e)))?,
        })
    }
}
