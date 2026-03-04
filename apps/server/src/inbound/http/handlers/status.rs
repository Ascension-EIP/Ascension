use axum::Json;
use serde::Serialize;

#[derive(Serialize)]
pub struct StatusResponseData {
    pub version: String,
    pub state: String,
}

pub async fn api_status() -> Json<StatusResponseData> {
    Json(StatusResponseData {
        version: "1.0".into(),
        state: "running...".into(),
    })
}
