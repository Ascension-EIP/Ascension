package com.ascension.mobilekotlin.data.network

import com.google.gson.annotations.SerializedName

data class UploadUrlRequest(
    val filename: String,
    @SerializedName("user_id")
    val userId: String
)

data class UploadUrlResponse(
    @SerializedName("video_id")
    val videoId: String,
    @SerializedName("upload_url")
    val uploadUrl: String
)

data class TriggerAnalysisRequest(
    @SerializedName("video_id")
    val videoId: String
)

data class TriggerAnalysisResponse(
    @SerializedName("analysis_id")
    val analysisId: String,
    @SerializedName("job_id")
    val jobId: String?,
    val status: String?
)

data class AnalysisResponse(
    val id: String?,
    val status: String?,
    val progress: Int?,
    @SerializedName("result_json")
    val resultJson: String?,
    @SerializedName("processing_time_ms")
    val processingTimeMs: Int?,
    @SerializedName("created_at")
    val createdAt: String?,
    @SerializedName("completed_at")
    val completedAt: String?,
    @SerializedName(value = "hints", alternate = ["hints_markdown", "coaching_hints"])
    val hintsMarkdown: String?
)
