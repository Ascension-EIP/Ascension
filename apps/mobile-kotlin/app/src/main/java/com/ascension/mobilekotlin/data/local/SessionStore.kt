package com.ascension.mobilekotlin.data.local

import android.content.Context

private const val PREFS_NAME = "ascension_prefs"

private object Keys {
    const val backendUrl = "backend_url"
    const val accessToken = "access_token"
    const val refreshToken = "refresh_token"
    const val userId = "user_id"
    const val username = "username"
    const val email = "email"
}

data class SessionData(
    val backendUrl: String,
    val accessToken: String?,
    val refreshToken: String?,
    val userId: String?,
    val username: String?,
    val email: String?
) {
    val isLoggedIn: Boolean get() = !accessToken.isNullOrBlank()
}

class SessionStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun load(defaultBackendUrl: String): SessionData {
        return SessionData(
            backendUrl = prefs.getString(Keys.backendUrl, defaultBackendUrl) ?: defaultBackendUrl,
            accessToken = prefs.getString(Keys.accessToken, null),
            refreshToken = prefs.getString(Keys.refreshToken, null),
            userId = prefs.getString(Keys.userId, null),
            username = prefs.getString(Keys.username, null),
            email = prefs.getString(Keys.email, null)
        )
    }

    fun saveBackendUrl(url: String) {
        prefs.edit().putString(Keys.backendUrl, url).apply()
    }

    fun saveTokens(
        accessToken: String,
        refreshToken: String,
        userId: String,
        username: String?,
        email: String?
    ) {
        prefs.edit()
            .putString(Keys.accessToken, accessToken)
            .putString(Keys.refreshToken, refreshToken)
            .putString(Keys.userId, userId)
            .putString(Keys.username, username)
            .putString(Keys.email, email)
            .apply()
    }

    fun clearSession() {
        prefs.edit()
            .remove(Keys.accessToken)
            .remove(Keys.refreshToken)
            .remove(Keys.userId)
            .remove(Keys.username)
            .remove(Keys.email)
            .apply()
    }
}
