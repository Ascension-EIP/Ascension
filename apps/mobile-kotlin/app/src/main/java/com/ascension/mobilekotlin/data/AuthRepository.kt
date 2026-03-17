package com.ascension.mobilekotlin.data

import com.ascension.mobilekotlin.data.local.SessionStore
import com.ascension.mobilekotlin.data.network.ApiClientFactory
import com.ascension.mobilekotlin.data.network.LoginRequest
import com.ascension.mobilekotlin.data.network.RegisterRequest

data class AppSession(
    val backendUrl: String,
    val userId: String?,
    val username: String?,
    val email: String?,
    val isLoggedIn: Boolean
)

class AuthRepository(
    private val store: SessionStore,
    defaultBackendUrl: String
) {
    private var current = store.load(defaultBackendUrl)

    fun session(): AppSession {
        return AppSession(
            backendUrl = current.backendUrl,
            userId = current.userId,
            username = current.username,
            email = current.email,
            isLoggedIn = current.isLoggedIn
        )
    }

    fun updateBackendUrl(url: String): AppSession {
        store.saveBackendUrl(url)
        current = current.copy(backendUrl = url)
        return session()
    }

    suspend fun login(email: String, password: String): AppSession {
        val api = ApiClientFactory.create(current.backendUrl)
        val response = api.login(LoginRequest(email = email, password = password))

        store.saveTokens(
            accessToken = response.accessToken,
            refreshToken = response.refreshToken ?: "",
            userId = response.userId,
            username = response.username,
            email = response.email ?: email
        )

        current = current.copy(
            accessToken = response.accessToken,
            refreshToken = response.refreshToken,
            userId = response.userId,
            username = response.username,
            email = response.email ?: email
        )

        return session()
    }

    suspend fun register(username: String, email: String, password: String): AppSession {
        val api = ApiClientFactory.create(current.backendUrl)
        val response = api.register(
            RegisterRequest(
                username = username,
                email = email,
                password = password
            )
        )

        store.saveTokens(
            accessToken = response.accessToken,
            refreshToken = response.refreshToken ?: "",
            userId = response.userId,
            username = response.username ?: username,
            email = response.email ?: email
        )

        current = current.copy(
            accessToken = response.accessToken,
            refreshToken = response.refreshToken,
            userId = response.userId,
            username = response.username ?: username,
            email = response.email ?: email
        )

        return session()
    }

    fun logout(): AppSession {
        store.clearSession()
        current = current.copy(
            accessToken = null,
            refreshToken = null,
            userId = null,
            username = null,
            email = null
        )
        return session()
    }
}
