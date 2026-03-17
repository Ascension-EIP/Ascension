package com.ascension.mobilekotlin.data.history

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

private const val PREFS_NAME = "ascension_prefs"
private const val KEY_PREFIX = "analysis_history_"

class AnalysisHistoryService(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val gson = Gson()

    private fun key(userId: String): String = "$KEY_PREFIX$userId"

    fun getHistory(userId: String): List<AnalysisHistoryEntry> {
        val raw = prefs.getString(key(userId), null) ?: return emptyList()
        return runCatching {
            val listType = object : TypeToken<List<AnalysisHistoryEntry>>() {}.type
            val list = gson.fromJson<List<AnalysisHistoryEntry>>(raw, listType) ?: emptyList()
            list.sortedByDescending { it.createdAtInstant }
        }.getOrElse { emptyList() }
    }

    fun saveEntry(userId: String, entry: AnalysisHistoryEntry) {
        val existing = getHistory(userId)
        val updated = existing
            .filterNot { it.analysisId == entry.analysisId }
            .toMutableList()
            .apply { add(entry) }

        prefs.edit()
            .putString(key(userId), gson.toJson(updated))
            .apply()
    }
}
