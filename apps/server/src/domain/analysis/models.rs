use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Analysis {
    pub id: Uuid,
    pub video_id: Uuid,
    pub job_id: Uuid,
    pub status: String,
    /// Real-time progress written by the AI worker (0–100).
    pub progress: i32,
    pub result_json: Option<String>,
    pub processing_time_ms: Option<i32>,
    pub completed_at: Option<NaiveDateTime>,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CreateAnalysisInput {
    pub video_id: Uuid,
    pub job_id: Uuid,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CreateAnalysisOutput {
    pub id: Uuid,
    pub job_id: Uuid,
}
