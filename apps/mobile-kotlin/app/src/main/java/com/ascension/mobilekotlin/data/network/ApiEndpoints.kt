package com.ascension.mobilekotlin.data.network

import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.POST

interface ApiEndpoints {
    @POST("/v1/auth/login")
    suspend fun login(@Body body: LoginRequest): AuthResponse

    @POST("/v1/auth/register")
    suspend fun register(@Body body: RegisterRequest): AuthResponse

    @POST("/v1/videos/upload-url")
    suspend fun getUploadUrl(@Body body: UploadUrlRequest): UploadUrlResponse

    @POST("/v1/analyses")
    suspend fun triggerAnalysis(@Body body: TriggerAnalysisRequest): TriggerAnalysisResponse

    @GET("/v1/analyses/{analysisId}")
    suspend fun getAnalysis(@Path("analysisId") analysisId: String): AnalysisResponse
}
