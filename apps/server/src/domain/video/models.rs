use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Video {
    pub id: Uuid,
    pub user_id: Uuid,
    pub object_key: String,
    pub bucket: String,
    pub filename: String,
    pub status: String,
    pub created_at: NaiveDateTime,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CreateVideoInput {
    pub user_id: Uuid,
    pub object_key: String,
    pub bucket: String,
    pub filename: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CreateVideoOutput {
    pub id: Uuid,
    pub object_key: String,
    pub bucket: String,
}
