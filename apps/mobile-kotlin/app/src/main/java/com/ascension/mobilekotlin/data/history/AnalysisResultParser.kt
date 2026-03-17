package com.ascension.mobilekotlin.data.history

import androidx.compose.ui.geometry.Offset
import org.json.JSONObject

data class AnalysisFrame(
    val frameIndex: Int,
    val timestampMs: Int,
    val poseDetected: Boolean,
    val landmarks: Map<Int, Offset>,
    val angles: Map<Int, Double>
)

data class AnalysisResultData(
    val frames: List<AnalysisFrame>,
    val hintsMarkdown: String?
) {
    val isEmpty: Boolean get() = frames.isEmpty()
}

object AnalysisResultParser {
    fun parse(resultJson: String?): AnalysisResultData {
        if (resultJson.isNullOrBlank()) return AnalysisResultData(emptyList(), null)
        return runCatching {
            val root = JSONObject(resultJson)
            val hints = listOf("hints", "hints_markdown", "coaching_hints")
                .firstNotNullOfOrNull { key -> root.optString(key).takeIf { it.isNotBlank() } }
            val framesArray = root.optJSONArray("frames") ?: return AnalysisResultData(emptyList(), hints)
            val frames = buildList {
                for (index in 0 until framesArray.length()) {
                    val frameObj = framesArray.optJSONObject(index) ?: continue
                    val landmarks = mutableMapOf<Int, Offset>()
                    val angles = mutableMapOf<Int, Double>()

                    val landmarksObj = frameObj.optJSONObject("landmarks")
                    if (landmarksObj != null) {
                        val keys = landmarksObj.keys()
                        while (keys.hasNext()) {
                            val key = keys.next()
                            val id = key.toIntOrNull() ?: continue
                            val point = landmarksObj.optJSONObject(key) ?: continue
                            landmarks[id] = Offset(
                                x = point.optDouble("x", 0.0).toFloat(),
                                y = point.optDouble("y", 0.0).toFloat()
                            )
                        }
                    }

                    val anglesObj = frameObj.optJSONObject("angles")
                    if (anglesObj != null) {
                        val keys = anglesObj.keys()
                        while (keys.hasNext()) {
                            val key = keys.next()
                            val id = key.toIntOrNull() ?: continue
                            angles[id] = anglesObj.optDouble(key, 0.0)
                        }
                    }

                    add(
                        AnalysisFrame(
                            frameIndex = frameObj.optInt("frame", index),
                            timestampMs = frameObj.optInt("timestamp_ms", 0),
                            poseDetected = frameObj.optBoolean("pose_detected", false),
                            landmarks = landmarks,
                            angles = angles
                        )
                    )
                }
            }
            AnalysisResultData(frames = frames, hintsMarkdown = hints)
        }.getOrDefault(AnalysisResultData(emptyList(), null))
    }
}
