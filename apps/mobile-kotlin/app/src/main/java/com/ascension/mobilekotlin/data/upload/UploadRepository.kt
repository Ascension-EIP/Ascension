package com.ascension.mobilekotlin.data.upload

import com.ascension.mobilekotlin.data.network.AnalysisResponse
import com.ascension.mobilekotlin.data.network.ApiClientFactory
import com.ascension.mobilekotlin.data.network.TriggerAnalysisRequest
import com.ascension.mobilekotlin.data.network.UploadUrlRequest
import kotlinx.coroutines.delay
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

data class UploadStage(
    val label: String,
    val progress: Float
)

data class AnalysisStage(
    val status: String,
    val progress: Int?
)

class UploadRepository(private val baseUrl: String) {
    private val api = ApiClientFactory.create(baseUrl)
    private val http = OkHttpClient()

    suspend fun uploadAndAnalyze(
        userId: String,
        fileName: String,
        fileBytes: ByteArray,
        mimeType: String,
        onUploadStage: (UploadStage) -> Unit,
        onAnalysisStage: (AnalysisStage) -> Unit
    ): AnalysisResponse {
        onUploadStage(UploadStage(label = "Préparation", progress = 0.05f))

        val uploadUrl = api.getUploadUrl(
            UploadUrlRequest(
                filename = fileName,
                userId = userId
            )
        )

        onUploadStage(UploadStage(label = "Upload vers MinIO", progress = 0.35f))

        val request = Request.Builder()
            .url(uploadUrl.uploadUrl)
            .put(fileBytes.toRequestBody(mimeType.toMediaTypeOrNull()))
            .addHeader("Content-Type", mimeType)
            .build()

        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw IllegalStateException(
                    "MinIO upload failed (${response.code}): ${response.body?.string().orEmpty()}"
                )
            }
        }

        onUploadStage(UploadStage(label = "Déclenchement de l'analyse", progress = 0.65f))

        val trigger = api.triggerAnalysis(TriggerAnalysisRequest(videoId = uploadUrl.videoId))

        onUploadStage(UploadStage(label = "Analyse en cours", progress = 0.75f))
        onAnalysisStage(AnalysisStage(status = trigger.status ?: "queued", progress = 0))

        val maxPolls = 120
        repeat(maxPolls) { pollIndex ->
            delay(5000)
            val analysis = api.getAnalysis(trigger.analysisId)
            val status = analysis.status.orEmpty()
            onAnalysisStage(AnalysisStage(status = status, progress = analysis.progress))

            if (status == "completed") return analysis
            if (status == "failed" && pollIndex >= 6) return analysis
        }

        throw IllegalStateException("L'analyse a dépassé le délai d'attente (10 min).")
    }
}
