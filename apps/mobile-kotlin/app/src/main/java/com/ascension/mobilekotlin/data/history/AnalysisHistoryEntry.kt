package com.ascension.mobilekotlin.data.history

import org.json.JSONObject
import java.time.Instant

data class AnalysisHistoryEntry(
    val analysisId: String,
    val createdAtIso: String,
    val completedAtIso: String?,
    val processingTimeMs: Int?,
    val resultJson: String?,
    val hintsMarkdown: String?,
    val status: String
) {
    val isCompleted: Boolean get() = status == "completed"

    val createdAtInstant: Instant
        get() = runCatching { Instant.parse(createdAtIso) }.getOrElse { Instant.EPOCH }

    val frameCount: Int
        get() {
            val payload = resultJson ?: return 0
            return runCatching {
                val frames = JSONObject(payload).optJSONArray("frames")
                frames?.length() ?: 0
            }.getOrDefault(0)
        }

    val detectedFrameCount: Int
        get() {
            val payload = resultJson ?: return 0
            return runCatching {
                val frames = JSONObject(payload).optJSONArray("frames") ?: return 0
                var detected = 0
                for (index in 0 until frames.length()) {
                    val frame = frames.optJSONObject(index)
                    if (frame?.optBoolean("pose_detected", false) == true) {
                        detected += 1
                    }
                }
                detected
            }.getOrDefault(0)
        }

    val detectionRate: Double
        get() {
            val payload = resultJson ?: return 0.0
            return runCatching {
                val frames = JSONObject(payload).optJSONArray("frames") ?: return 0.0
                if (frames.length() == 0) return 0.0
                val detected = detectedFrameCount
                detected.toDouble() / frames.length().toDouble() * 100.0
            }.getOrDefault(0.0)
        }

    val prettyResultJson: String
        get() {
            val payload = resultJson ?: return "Aucun résultat JSON"
            return runCatching {
                JSONObject(payload).toString(2)
            }.getOrElse { payload }
        }
}
