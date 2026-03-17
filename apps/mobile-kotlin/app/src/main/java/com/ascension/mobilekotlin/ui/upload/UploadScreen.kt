package com.ascension.mobilekotlin.ui.upload

import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import androidx.core.net.toUri
import com.ascension.mobilekotlin.data.history.AnalysisHistoryEntry
import com.ascension.mobilekotlin.data.history.AnalysisHistoryService
import com.ascension.mobilekotlin.data.network.AnalysisResponse
import com.ascension.mobilekotlin.data.upload.AnalysisStage
import com.ascension.mobilekotlin.data.upload.UploadRepository
import com.ascension.mobilekotlin.data.upload.UploadStage
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.io.File

private enum class UploadUiState {
    Idle,
    Selected,
    Uploading,
    Analysing,
    Done,
    Error
}

@Composable
fun UploadScreen(
    backendUrl: String,
    userId: String?
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val repository = remember(backendUrl) { UploadRepository(backendUrl) }
    val historyService = remember { AnalysisHistoryService(context) }

    var state by rememberSaveable { mutableStateOf(UploadUiState.Idle) }
    var selectedUri by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedFileName by rememberSaveable { mutableStateOf<String?>(null) }
    var uploadProgress by rememberSaveable { mutableStateOf(0f) }
    var uploadLabel by rememberSaveable { mutableStateOf("Prêt") }
    var analysisStatus by rememberSaveable { mutableStateOf<String?>(null) }
    var analysisProgress by rememberSaveable { mutableStateOf<Int?>(null) }
    var errorMessage by rememberSaveable { mutableStateOf<String?>(null) }
    var pendingCameraUri by rememberSaveable { mutableStateOf<String?>(null) }
    var pendingCameraFileName by rememberSaveable { mutableStateOf<String?>(null) }
    var analysisResult by remember { mutableStateOf<AnalysisResponse?>(null) }
    var activeUploadJob by remember { mutableStateOf<Job?>(null) }

    val isUploading = state == UploadUiState.Uploading || state == UploadUiState.Analysing

    fun selectVideo(uriString: String, providedName: String? = null) {
        val name = providedName ?: readDisplayName(uriString, context) ?: "video.mp4"
        selectedUri = uriString
        selectedFileName = name
        errorMessage = null
        analysisResult = null
        analysisStatus = null
        analysisProgress = null
        uploadProgress = 0f
        uploadLabel = "Vidéo sélectionnée"
        state = UploadUiState.Selected
    }

    val picker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        if (uri != null) {
            selectVideo(uri.toString())
        }
    }

    val cameraCapture = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CaptureVideo()
    ) { success ->
        val uriString = pendingCameraUri
        if (success && uriString != null) {
            selectVideo(uriString, pendingCameraFileName)
        } else {
            errorMessage = "Capture vidéo annulée."
        }
        pendingCameraUri = null
        pendingCameraFileName = null
    }

    fun launchAnalysisForSelection() {
        val uri = selectedUri?.toUri() ?: run {
            errorMessage = "Sélectionnez une vidéo avant de lancer l'analyse."
            return
        }
        val fileName = selectedFileName ?: "video.mp4"
        val activeUserId = userId ?: run {
            errorMessage = "Utilisateur non connecté."
            return
        }

        if (activeUploadJob?.isActive == true) return

        activeUploadJob = scope.launch {
            try {
                state = UploadUiState.Uploading
                errorMessage = null
                analysisResult = null
                analysisStatus = null
                analysisProgress = null
                uploadProgress = 0f
                uploadLabel = "Préparation de l'envoi"

                val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                    ?: throw IllegalStateException("Impossible de lire la vidéo sélectionnée.")

                val mimeType = guessMimeType(fileName)

                val result = repository.uploadAndAnalyze(
                    userId = activeUserId,
                    fileName = fileName,
                    fileBytes = bytes,
                    mimeType = mimeType,
                    onUploadStage = { stage: UploadStage ->
                        uploadLabel = stage.label
                        uploadProgress = stage.progress
                        if (stage.progress >= 0.7f) {
                            state = UploadUiState.Analysing
                        }
                    },
                    onAnalysisStage = { stage: AnalysisStage ->
                        analysisStatus = stage.status
                        analysisProgress = stage.progress
                    }
                )

                historyService.saveEntry(
                    userId = activeUserId,
                    entry = AnalysisHistoryEntry(
                        analysisId = result.id ?: "",
                        createdAtIso = result.createdAt ?: java.time.Instant.now().toString(),
                        completedAtIso = result.completedAt,
                        processingTimeMs = result.processingTimeMs,
                        resultJson = result.resultJson,
                        hintsMarkdown = result.hintsMarkdown,
                        status = result.status ?: "unknown"
                    )
                )

                analysisResult = result
                uploadProgress = 1f
                uploadLabel = "Terminé"
                state = UploadUiState.Done
            } catch (_: CancellationException) {
                uploadLabel = "Annulé"
                analysisStatus = null
                analysisProgress = null
                uploadProgress = 0f
                state = if (selectedUri == null) UploadUiState.Idle else UploadUiState.Selected
            } catch (exception: Throwable) {
                errorMessage = exception.message ?: "Erreur inconnue pendant l'upload/analyse."
                state = UploadUiState.Error
            } finally {
                activeUploadJob = null
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "Uploader une vidéo",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = "Filmez ou importez votre session pour lancer l'analyse biomécanique.",
            style = MaterialTheme.typography.bodyMedium
        )

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("Fichier", style = MaterialTheme.typography.labelLarge)
                Text(selectedFileName ?: "Aucune vidéo sélectionnée")

                Row(modifier = Modifier.fillMaxWidth()) {
                    OutlinedButton(
                        modifier = Modifier.weight(1f),
                        enabled = !isUploading,
                        onClick = {
                            val (cameraUri, fileName) = createCaptureTarget(context)
                            pendingCameraUri = cameraUri.toString()
                            pendingCameraFileName = fileName
                            cameraCapture.launch(cameraUri)
                        }
                    ) {
                        Text("Filmer")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    OutlinedButton(
                        modifier = Modifier.weight(1f),
                        enabled = !isUploading,
                        onClick = { picker.launch("video/*") }
                    ) {
                        Text("Importer")
                    }
                }
            }
        }

        if (state == UploadUiState.Uploading || state == UploadUiState.Analysing || state == UploadUiState.Done) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(uploadLabel)
                    LinearProgressIndicator(progress = { uploadProgress }, modifier = Modifier.fillMaxWidth())
                    Text("Upload ${(uploadProgress * 100).toInt()}%")

                    if (analysisStatus != null) {
                        val progressLabel = analysisProgress?.let { "$it%" } ?: "..."
                        Text("Analyse: ${analysisStatus} ($progressLabel)")
                    }
                }
            }
        }

        if (state == UploadUiState.Done && analysisResult != null) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text("Analyse terminée", fontWeight = FontWeight.Bold)
                    Text("Status: ${analysisResult?.status ?: "unknown"}")
                    Text("ID: ${analysisResult?.id ?: "n/a"}")
                    Text("Progress: ${analysisResult?.progress ?: 100}%")
                }
            }
        }

        if (errorMessage != null) {
            Text(
                text = errorMessage.orEmpty(),
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodyMedium
            )

            if (selectedUri != null && userId != null) {
                Spacer(modifier = Modifier.height(4.dp))
                OutlinedButton(
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isUploading,
                    onClick = { launchAnalysisForSelection() }
                ) {
                    Text("Réessayer")
                }
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        Button(
            modifier = Modifier.fillMaxWidth(),
            enabled = state == UploadUiState.Selected && userId != null && !isUploading,
            onClick = { launchAnalysisForSelection() }
        ) {
            Text(if (userId == null) "Utilisateur non connecté" else "Lancer l'analyse")
        }

        if (isUploading) {
            OutlinedButton(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    activeUploadJob?.cancel()
                }
            ) {
                Text("Annuler")
            }
        }

        OutlinedButton(
            modifier = Modifier.fillMaxWidth(),
            enabled = !isUploading,
            onClick = {
                activeUploadJob?.cancel()
                state = if (selectedUri == null) UploadUiState.Idle else UploadUiState.Selected
                uploadProgress = 0f
                uploadLabel = "Prêt"
                analysisStatus = null
                analysisProgress = null
                analysisResult = null
                errorMessage = null
            }
        ) {
            Text("Réinitialiser")
        }
    }
}

private fun readDisplayName(uriString: String, context: android.content.Context): String? {
    val uri = uriString.toUri()
    val cursor = context.contentResolver.query(uri, null, null, null, null) ?: return null
    cursor.use {
        val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
        if (nameIndex >= 0 && it.moveToFirst()) {
            return it.getString(nameIndex)
        }
    }
    return null
}

private fun guessMimeType(fileName: String): String {
    return when (fileName.substringAfterLast('.', "").lowercase()) {
        "mov" -> "video/quicktime"
        "avi" -> "video/x-msvideo"
        "webm" -> "video/webm"
        else -> "video/mp4"
    }
}

private fun createCaptureTarget(context: android.content.Context): Pair<Uri, String> {
    val videosDir = File(context.cacheDir, "videos").apply { mkdirs() }
    val fileName = "capture_${System.currentTimeMillis()}.mp4"
    val file = File(videosDir, fileName)
    val uri = FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
    )
    return uri to fileName
}
