package com.ascension.mobilekotlin.ui.analysis

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.ClickableText
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.ascension.mobilekotlin.data.history.AnalysisResultParser
import kotlin.math.abs
import kotlinx.coroutines.delay

private val skeletonConnections = listOf(
    11 to 12,
    11 to 13,
    13 to 15,
    12 to 14,
    14 to 16,
    11 to 23,
    12 to 24,
    23 to 24,
    23 to 25,
    25 to 27,
    24 to 26,
    26 to 28
)

@Composable
fun AnalysisViewerScreen(
    resultJson: String,
    hintsMarkdown: String?,
    onBack: () -> Unit
) {
    val data = remember(resultJson) { AnalysisResultParser.parse(resultJson) }
    val hints = hintsMarkdown ?: data.hintsMarkdown

    if (data.isEmpty) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text("Visualisation", style = MaterialTheme.typography.headlineSmall)
            Text("Aucune frame exploitable dans le résultat JSON.")
            Button(onClick = onBack) { Text("Retour") }
        }
        return
    }

    var currentIndex by remember { mutableIntStateOf(0) }
    var sliderValue by remember { mutableFloatStateOf(0f) }
    var playing by remember { mutableStateOf(false) }
    val uriHandler = LocalUriHandler.current

    val frame = data.frames[currentIndex]

    fun seekToTimestamp(timestampMs: Int) {
        val nearestIndex = data.frames
            .indices
            .minByOrNull { index -> abs(data.frames[index].timestampMs - timestampMs) }
            ?: return
        playing = false
        currentIndex = nearestIndex
        sliderValue = nearestIndex.toFloat()
    }

    LaunchedEffect(playing, currentIndex) {
        if (!playing) return@LaunchedEffect
        while (playing) {
            delay(120)
            currentIndex = (currentIndex + 1).coerceAtMost(data.frames.lastIndex)
            sliderValue = currentIndex.toFloat()
            if (currentIndex == data.frames.lastIndex) {
                playing = false
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Visualisation", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Button(onClick = onBack) { Text("Retour") }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("Frame ${frame.frameIndex} / ${data.frames.last().frameIndex}")
                Text("Timestamp: ${frame.timestampMs} ms")
                Text("Pose détectée: ${if (frame.poseDetected) "Oui" else "Non"}")
            }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Squelette")
                Canvas(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(320.dp)
                        .background(Color(0xFF0D1B2A))
                ) {
                    val width = size.width
                    val height = size.height

                    fun project(offset: Offset): Offset {
                        return Offset(x = offset.x * width, y = offset.y * height)
                    }

                    for ((a, b) in skeletonConnections) {
                        val pa = frame.landmarks[a]
                        val pb = frame.landmarks[b]
                        if (pa != null && pb != null) {
                            drawLine(
                                color = Color(0xFF3DDC97),
                                start = project(pa),
                                end = project(pb),
                                strokeWidth = 4f
                            )
                        }
                    }

                    frame.landmarks.values.forEach { lm ->
                        val point = project(lm)
                        drawCircle(
                            color = Color.White,
                            radius = 6f,
                            center = point,
                            style = Stroke(width = 2f)
                        )
                    }
                }
            }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Timeline")
                Slider(
                    value = sliderValue,
                    onValueChange = {
                        sliderValue = it
                        currentIndex = it.toInt().coerceIn(0, data.frames.lastIndex)
                    },
                    valueRange = 0f..data.frames.lastIndex.toFloat()
                )
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        modifier = Modifier.weight(1f),
                        onClick = {
                            playing = false
                            currentIndex = (currentIndex - 1).coerceAtLeast(0)
                            sliderValue = currentIndex.toFloat()
                        }
                    ) {
                        Text("Précédent")
                    }
                    Button(
                        modifier = Modifier.weight(1f),
                        onClick = {
                            playing = !playing
                        }
                    ) {
                        Text(if (playing) "Pause" else "Lecture")
                    }
                    Button(
                        modifier = Modifier.weight(1f),
                        onClick = {
                            playing = false
                            currentIndex = (currentIndex + 1).coerceAtMost(data.frames.lastIndex)
                            sliderValue = currentIndex.toFloat()
                        }
                    ) {
                        Text("Suivant")
                    }
                }
            }
        }

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("Angles clés")
                Text("Coude G (13): ${frame.angles[13]?.let { String.format("%.1f°", it) } ?: "n/a"}")
                Text("Coude D (14): ${frame.angles[14]?.let { String.format("%.1f°", it) } ?: "n/a"}")
                Text("Genou G (25): ${frame.angles[25]?.let { String.format("%.1f°", it) } ?: "n/a"}")
                Text("Genou D (26): ${frame.angles[26]?.let { String.format("%.1f°", it) } ?: "n/a"}")
            }
        }

        if (!hints.isNullOrBlank()) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Coaching hints", style = MaterialTheme.typography.titleMedium)
                    HintsMarkdownBlock(
                        markdown = hints,
                        onTimestampClick = { timestampMs ->
                            seekToTimestamp(timestampMs)
                        },
                        onUrlClick = { url ->
                            runCatching { uriHandler.openUri(url) }
                        }
                    )
                }
            }
        }
    }
}

private const val TIMECODE_TAG = "timecode"
private const val URL_TAG = "url"
private val timecodeRegex = Regex("\\b(?:(\\d{1,2}):)?([0-5]?\\d):([0-5]?\\d(?:\\.\\d+)?)\\b")
private val urlRegex = Regex("\\bhttps?://[\\w._~:/?#\\[\\]@!$&'()*+,;=%-]+")
private val markdownLinkRegex = Regex("\\[([^\\]]+)]\\((https?://[^)]+)\\)")

private enum class HintBlockType { Heading, Bullet, Ordered, Paragraph }

private data class HintBlock(
    val type: HintBlockType,
    val text: String,
    val level: Int = 0,
    val orderNumber: Int? = null
)

@Composable
private fun HintsMarkdownBlock(
    markdown: String,
    onTimestampClick: (Int) -> Unit,
    onUrlClick: (String) -> Unit
) {
    val blocks = remember(markdown) { parseHintBlocks(markdown) }
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        blocks.forEach { block ->
            when (block.type) {
                HintBlockType.Heading -> {
                    val style = when (block.level.coerceIn(1, 6)) {
                        1 -> MaterialTheme.typography.titleLarge
                        2 -> MaterialTheme.typography.titleMedium
                        else -> MaterialTheme.typography.titleSmall
                    }
                    InteractiveHintText(
                        text = block.text,
                        style = style,
                        onTimestampClick = onTimestampClick,
                        onUrlClick = onUrlClick
                    )
                }

                HintBlockType.Bullet -> {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("•", style = MaterialTheme.typography.bodySmall)
                        InteractiveHintText(
                            modifier = Modifier.weight(1f),
                            text = block.text,
                            style = MaterialTheme.typography.bodySmall,
                            onTimestampClick = onTimestampClick,
                            onUrlClick = onUrlClick
                        )
                    }
                }

                HintBlockType.Ordered -> {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("${block.orderNumber ?: 1}.", style = MaterialTheme.typography.bodySmall)
                        InteractiveHintText(
                            modifier = Modifier.weight(1f),
                            text = block.text,
                            style = MaterialTheme.typography.bodySmall,
                            onTimestampClick = onTimestampClick,
                            onUrlClick = onUrlClick
                        )
                    }
                }

                HintBlockType.Paragraph -> {
                    InteractiveHintText(
                        text = block.text,
                        style = MaterialTheme.typography.bodySmall,
                        onTimestampClick = onTimestampClick,
                        onUrlClick = onUrlClick
                    )
                }
            }
        }
    }
}

@Composable
private fun InteractiveHintText(
    text: String,
    style: androidx.compose.ui.text.TextStyle,
    modifier: Modifier = Modifier,
    onTimestampClick: (Int) -> Unit,
    onUrlClick: (String) -> Unit
) {
    val annotatedHints = remember(text) {
        buildAnnotatedString {
            val expanded = replaceMarkdownLinks(text)
            var lastIndex = 0
            val matches = combinedTokenRegex.findAll(expanded)
            for (match in matches) {
                val range = match.range
                append(expanded.substring(lastIndex, range.first))

                val token = match.value
                val start = length
                append(token)
                val end = length

                when {
                    urlRegex.matches(token) -> {
                        addStyle(
                            style = SpanStyle(
                                color = Color(0xFF64B5F6),
                                textDecoration = TextDecoration.Underline
                            ),
                            start = start,
                            end = end
                        )
                        addStringAnnotation(
                            tag = URL_TAG,
                            annotation = token,
                            start = start,
                            end = end
                        )
                    }

                    timecodeRegex.matches(token) -> {
                        addStyle(
                            style = SpanStyle(
                                color = Color(0xFF3DDC97),
                                textDecoration = TextDecoration.Underline
                            ),
                            start = start,
                            end = end
                        )
                        addStringAnnotation(
                            tag = TIMECODE_TAG,
                            annotation = token,
                            start = start,
                            end = end
                        )
                    }
                }

                lastIndex = range.last + 1
            }

            if (lastIndex < expanded.length) {
                append(expanded.substring(lastIndex))
            }
        }
    }

    ClickableText(
        modifier = modifier,
        text = annotatedHints,
        style = style,
        onClick = { offset ->
            val urlAnnotation = annotatedHints
                .getStringAnnotations(URL_TAG, offset, offset)
                .firstOrNull()
                ?.item
            if (urlAnnotation != null) {
                onUrlClick(urlAnnotation)
                return@ClickableText
            }

            val timestampAnnotation = annotatedHints
                .getStringAnnotations(TIMECODE_TAG, offset, offset)
                .firstOrNull()
                ?.item
                ?: return@ClickableText

            parseTimecodeToMs(timestampAnnotation)?.let(onTimestampClick)
        }
    )
}

private val combinedTokenRegex = Regex("${urlRegex.pattern}|${timecodeRegex.pattern}")

private fun parseHintBlocks(markdown: String): List<HintBlock> {
    val blocks = mutableListOf<HintBlock>()
    markdown.lines().forEach { rawLine ->
        val line = rawLine.trimEnd()
        if (line.isBlank()) return@forEach

        val headingMatch = Regex("^(#{1,6})\\s+(.*)$").find(line)
        if (headingMatch != null) {
            blocks += HintBlock(
                type = HintBlockType.Heading,
                text = headingMatch.groupValues[2].trim(),
                level = headingMatch.groupValues[1].length
            )
            return@forEach
        }

        val orderedMatch = Regex("^(\\d+)\\.\\s+(.*)$").find(line.trimStart())
        if (orderedMatch != null) {
            blocks += HintBlock(
                type = HintBlockType.Ordered,
                text = orderedMatch.groupValues[2].trim(),
                orderNumber = orderedMatch.groupValues[1].toIntOrNull()
            )
            return@forEach
        }

        val bulletMatch = Regex("^[-*]\\s+(.*)$").find(line.trimStart())
        if (bulletMatch != null) {
            blocks += HintBlock(
                type = HintBlockType.Bullet,
                text = bulletMatch.groupValues[1].trim()
            )
            return@forEach
        }

        blocks += HintBlock(type = HintBlockType.Paragraph, text = line.trim())
    }

    return blocks
}

private fun replaceMarkdownLinks(input: String): String {
    return markdownLinkRegex.replace(input) { matchResult ->
        val label = matchResult.groupValues[1]
        val url = matchResult.groupValues[2]
        "$label ($url)"
    }
}

private fun parseTimecodeToMs(token: String): Int? {
    val match = timecodeRegex.matchEntire(token) ?: return null
    val hours = match.groupValues[1].takeIf { it.isNotBlank() }?.toIntOrNull() ?: 0
    val minutes = match.groupValues[2].toIntOrNull() ?: return null
    val secondsDouble = match.groupValues[3].toDoubleOrNull() ?: return null
    val totalMs = ((hours * 3600) + (minutes * 60)) * 1000 + (secondsDouble * 1000).toInt()
    return totalMs.coerceAtLeast(0)
}
