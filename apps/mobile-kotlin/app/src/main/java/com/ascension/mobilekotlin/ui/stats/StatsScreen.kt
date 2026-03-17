package com.ascension.mobilekotlin.ui.stats

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ascension.mobilekotlin.data.history.AnalysisHistoryEntry
import com.ascension.mobilekotlin.data.history.AnalysisHistoryService
import com.ascension.mobilekotlin.ui.analysis.AnalysisViewerScreen
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun StatsScreen(userId: String?) {
    val context = LocalContext.current
    val historyService = remember { AnalysisHistoryService(context) }
    var entries by remember(userId) {
        mutableStateOf(
            if (userId == null) emptyList() else historyService.getHistory(userId)
        )
    }
    var selectedEntry by remember { mutableStateOf<AnalysisHistoryEntry?>(null) }
    var visualizedResultJson by remember { mutableStateOf<String?>(null) }
    var visualizedHints by remember { mutableStateOf<String?>(null) }

    if (visualizedResultJson != null) {
        AnalysisViewerScreen(
            resultJson = visualizedResultJson!!,
            hintsMarkdown = visualizedHints,
            onBack = {
                visualizedResultJson = null
                visualizedHints = null
            }
        )
        return
    }

    if (selectedEntry != null) {
        AnalysisDetailScreen(
            entry = selectedEntry!!,
            onBack = { selectedEntry = null },
            onOpenVisualization = {
                val json = selectedEntry?.resultJson
                if (!json.isNullOrBlank()) {
                    visualizedResultJson = json
                    visualizedHints = selectedEntry?.hintsMarkdown
                }
            }
        )
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Statistiques",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            OutlinedButton(
                enabled = userId != null,
                onClick = {
                    if (userId != null) {
                        entries = historyService.getHistory(userId)
                    }
                }
            ) {
                Text("Rafraîchir")
            }
        }

        if (userId == null) {
            Text("Utilisateur non connecté")
            return@Column
        }

        if (entries.isEmpty()) {
            Text("Aucune analyse enregistrée pour le moment.")
            return@Column
        }

        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(entries) { entry ->
                AnalysisCard(
                    entry = entry,
                    onOpenDetails = { selectedEntry = entry }
                )
            }
        }
    }
}

@Composable
private fun AnalysisCard(
    entry: AnalysisHistoryEntry,
    onOpenDetails: () -> Unit
) {
    val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
    val localDate = entry.createdAtInstant.atZone(ZoneId.systemDefault()).format(formatter)
    val processingSeconds = entry.processingTimeMs?.let { String.format("%.1f", it / 1000.0) }

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = if (entry.isCompleted) "Analyse terminée" else "Analyse ${entry.status}",
                fontWeight = FontWeight.SemiBold
            )
            Text("Date: $localDate")
            Text("Frames: ${entry.frameCount}")
            Text("Détection: ${String.format("%.0f", entry.detectionRate)}%")
            if (processingSeconds != null) {
                Text("Temps de traitement: ${processingSeconds}s")
            }
            Spacer(modifier = Modifier.height(4.dp))
            OutlinedButton(
                modifier = Modifier.fillMaxWidth(),
                onClick = onOpenDetails
            ) {
                Text("Voir détails")
            }
        }
    }
}

@Composable
private fun AnalysisDetailScreen(
    entry: AnalysisHistoryEntry,
    onBack: () -> Unit,
    onOpenVisualization: () -> Unit
) {
    val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
    val localDate = entry.createdAtInstant.atZone(ZoneId.systemDefault()).format(formatter)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Détail analyse", style = MaterialTheme.typography.headlineSmall)
            Button(onClick = onBack) { Text("Retour") }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text("ID: ${entry.analysisId}")
                Text("Status: ${entry.status}")
                Text("Date: $localDate")
                Text("Frames détectées: ${entry.detectedFrameCount}/${entry.frameCount}")
                Text("Taux détection: ${String.format("%.2f", entry.detectionRate)}%")
                if (entry.processingTimeMs != null) {
                    Text("Temps traitement: ${String.format("%.1f", entry.processingTimeMs / 1000.0)}s")
                }

                if (!entry.resultJson.isNullOrBlank()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Button(onClick = onOpenVisualization) {
                        Text("Ouvrir visualisation")
                    }
                }
            }
        }

        Text("Résultat JSON", style = MaterialTheme.typography.titleMedium)
        Card(modifier = Modifier.fillMaxWidth()) {
            SelectionContainer {
                Text(
                    text = entry.prettyResultJson,
                    modifier = Modifier.padding(12.dp),
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}
