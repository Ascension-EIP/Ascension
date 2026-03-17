package com.ascension.mobilekotlin

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.UploadFile
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.ascension.mobilekotlin.core.audio.AudioService
import com.ascension.mobilekotlin.data.AppSession
import com.ascension.mobilekotlin.data.AuthRepository
import com.ascension.mobilekotlin.data.local.SessionStore
import com.ascension.mobilekotlin.ui.stats.StatsScreen
import com.ascension.mobilekotlin.ui.upload.UploadScreen
import kotlinx.coroutines.launch
import retrofit2.HttpException
import java.io.IOException

private enum class MainTab(val label: String) {
	Home("Home"),
	Upload("Upload"),
	Stats("Stats"),
	Profile("Profile")
}

@Composable
fun AscensionApp() {
	MaterialTheme {
		val context = LocalContext.current
		val audioService = remember { AudioService.getInstance(context) }
		LaunchedEffect(Unit) {
			audioService.init()
		}
		val repository = remember {
			AuthRepository(
				store = SessionStore(context),
				defaultBackendUrl = BuildConfig.DEFAULT_BACKEND_URL
			)
		}

		var session by remember { mutableStateOf(repository.session()) }
		var authPage by rememberSaveable { mutableStateOf(0) }
		Scaffold(snackbarHost = { SnackbarHost(remember { SnackbarHostState() }) }) { innerPadding ->
			if (!session.isLoggedIn) {
				AuthRoot(
					modifier = Modifier.padding(innerPadding),
					initialPage = authPage,
					backendUrl = session.backendUrl,
					onAuthSuccess = {
						session = it
					},
					onSwitchPage = { authPage = it },
					onBackendUrlChanged = { url ->
						session = repository.updateBackendUrl(url)
					},
					repository = repository
				)
			} else {
				MainRoot(
					modifier = Modifier.padding(innerPadding),
					session = session,
					audioService = audioService,
					onLogout = { session = repository.logout() },
					onBackendUrlChanged = { url ->
						session = repository.updateBackendUrl(url)
					}
				)
			}
		}
	}
}

@Composable
private fun AuthRoot(
	modifier: Modifier,
	initialPage: Int,
	backendUrl: String,
	onAuthSuccess: (AppSession) -> Unit,
	onSwitchPage: (Int) -> Unit,
	onBackendUrlChanged: (String) -> Unit,
	repository: AuthRepository
) {
	var selectedTab by rememberSaveable { mutableStateOf(initialPage.coerceIn(0, 1)) }
	var errorMessage by rememberSaveable { mutableStateOf<String?>(null) }

	LaunchedEffect(selectedTab) {
		onSwitchPage(selectedTab)
	}

	Column(modifier = modifier.fillMaxSize()) {
		TabRow(selectedTabIndex = selectedTab) {
			Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }, text = { Text("Connexion") })
			Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }, text = { Text("Inscription") })
		}

		if (selectedTab == 0) {
			LoginScreen(
				backendUrl = backendUrl,
				onBackendUrlChanged = onBackendUrlChanged,
				errorMessage = errorMessage,
				onSubmit = { email, password ->
					runCatching { repository.login(email, password) }
						.onSuccess {
							errorMessage = null
							onAuthSuccess(it)
						}
						.onFailure { errorMessage = it.toReadableError() }
				}
			)
		} else {
			RegisterScreen(
				backendUrl = backendUrl,
				onBackendUrlChanged = onBackendUrlChanged,
				errorMessage = errorMessage,
				onSubmit = { username, email, password ->
					runCatching { repository.register(username, email, password) }
						.onSuccess {
							errorMessage = null
							onAuthSuccess(it)
						}
						.onFailure { errorMessage = it.toReadableError() }
				}
			)
		}
	}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainRoot(
	modifier: Modifier,
	session: AppSession,
	audioService: AudioService,
	onLogout: () -> Unit,
	onBackendUrlChanged: (String) -> Unit
) {
	var selectedTab by rememberSaveable { mutableStateOf(MainTab.Home) }
	var openSettings by rememberSaveable { mutableStateOf(false) }
	var musicEnabled by rememberSaveable { mutableStateOf(audioService.musicEnabled) }

	LaunchedEffect(Unit) {
		musicEnabled = audioService.musicEnabled
	}

	if (openSettings) {
		SettingsScreen(
			backendUrl = session.backendUrl,
			musicEnabled = musicEnabled,
			onMusicEnabledChanged = {
				audioService.setMusicEnabled(it)
				musicEnabled = it
			},
			onClose = { openSettings = false },
			onSave = {
				onBackendUrlChanged(it)
				openSettings = false
			}
		)
	}

	Scaffold(
		modifier = modifier,
		topBar = {
			TopAppBar(
				title = { Text("Ascension") },
				actions = {
					IconButton(onClick = { openSettings = true }) {
						Icon(Icons.Default.Settings, contentDescription = "Paramètres")
					}
				}
			)
		},
		bottomBar = {
			NavigationBar {
				NavigationBarItem(
					selected = selectedTab == MainTab.Home,
					onClick = { selectedTab = MainTab.Home },
					icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
					label = { Text(MainTab.Home.label) }
				)
				NavigationBarItem(
					selected = selectedTab == MainTab.Upload,
					onClick = { selectedTab = MainTab.Upload },
					icon = { Icon(Icons.Default.UploadFile, contentDescription = "Upload") },
					label = { Text(MainTab.Upload.label) }
				)
				NavigationBarItem(
					selected = selectedTab == MainTab.Stats,
					onClick = { selectedTab = MainTab.Stats },
					icon = { Icon(Icons.Default.BarChart, contentDescription = "Stats") },
					label = { Text(MainTab.Stats.label) }
				)
				NavigationBarItem(
					selected = selectedTab == MainTab.Profile,
					onClick = { selectedTab = MainTab.Profile },
					icon = { Icon(Icons.Default.Person, contentDescription = "Profile") },
					label = { Text(MainTab.Profile.label) }
				)
			}
		}
	) { innerPadding ->
		when (selectedTab) {
			MainTab.Home -> PlaceholderPage(innerPadding, "Visualiser l'invisible", "Accueil en Kotlin prêt.")
			MainTab.Upload -> UploadTab(
				innerPadding = innerPadding,
				backendUrl = session.backendUrl,
				userId = session.userId
			)
			MainTab.Stats -> StatsTab(
				innerPadding = innerPadding,
				userId = session.userId
			)
			MainTab.Profile -> ProfileScreen(innerPadding, session, onLogout)
		}
	}
}

@Composable
private fun UploadTab(
	innerPadding: androidx.compose.foundation.layout.PaddingValues,
	backendUrl: String,
	userId: String?
) {
	Column(
		modifier = Modifier
			.padding(innerPadding)
			.fillMaxSize()
	) {
		UploadScreen(
			backendUrl = backendUrl,
			userId = userId
		)
	}
}

@Composable
private fun StatsTab(
	innerPadding: androidx.compose.foundation.layout.PaddingValues,
	userId: String?
) {
	Column(
		modifier = Modifier
			.padding(innerPadding)
			.fillMaxSize()
	) {
		StatsScreen(userId = userId)
	}
}

@Composable
private fun LoginScreen(
	backendUrl: String,
	onBackendUrlChanged: (String) -> Unit,
	errorMessage: String?,
	onSubmit: suspend (String, String) -> Unit
) {
	AuthForm(
		title = "Connexion",
		subtitle = "Bienvenue ! Connectez-vous pour continuer.",
		backendUrl = backendUrl,
		onBackendUrlChanged = onBackendUrlChanged,
		showUsername = false,
		errorMessage = errorMessage,
		onSubmit = { username, email, password ->
			onSubmit(email, password)
		}
	)
}

@Composable
private fun RegisterScreen(
	backendUrl: String,
	onBackendUrlChanged: (String) -> Unit,
	errorMessage: String?,
	onSubmit: suspend (String, String, String) -> Unit
) {
	AuthForm(
		title = "Inscription",
		subtitle = "Créez un compte Ascension.",
		backendUrl = backendUrl,
		onBackendUrlChanged = onBackendUrlChanged,
		showUsername = true,
		errorMessage = errorMessage,
		onSubmit = { username, email, password ->
			onSubmit(username.orEmpty(), email, password)
		}
	)
}

@Composable
private fun AuthForm(
	title: String,
	subtitle: String,
	backendUrl: String,
	onBackendUrlChanged: (String) -> Unit,
	showUsername: Boolean,
	errorMessage: String?,
	onSubmit: suspend (String?, String, String) -> Unit
) {
	val scope = rememberCoroutineScope()
	var username by rememberSaveable { mutableStateOf("") }
	var email by rememberSaveable { mutableStateOf("") }
	var password by rememberSaveable { mutableStateOf("") }
	var urlInput by rememberSaveable(backendUrl) { mutableStateOf(backendUrl) }
	var loading by rememberSaveable { mutableStateOf(false) }

	Column(
		modifier = Modifier
			.fillMaxSize()
			.padding(20.dp)
			.verticalScroll(rememberScrollState()),
		verticalArrangement = Arrangement.spacedBy(12.dp)
	) {
		Text(text = title, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
		Text(text = subtitle, style = MaterialTheme.typography.bodyMedium)

		if (showUsername) {
			OutlinedTextField(
				modifier = Modifier.fillMaxWidth(),
				value = username,
				onValueChange = { username = it },
				label = { Text("Nom d'utilisateur") },
				singleLine = true
			)
		}

		OutlinedTextField(
			modifier = Modifier.fillMaxWidth(),
			value = email,
			onValueChange = { email = it },
			label = { Text("Email") },
			singleLine = true
		)

		OutlinedTextField(
			modifier = Modifier.fillMaxWidth(),
			value = password,
			onValueChange = { password = it },
			label = { Text("Mot de passe") },
			visualTransformation = PasswordVisualTransformation(),
			singleLine = true
		)

		Card(modifier = Modifier.fillMaxWidth()) {
			Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
				Text("URL backend", style = MaterialTheme.typography.labelLarge)
				OutlinedTextField(
					modifier = Modifier.fillMaxWidth(),
					value = urlInput,
					onValueChange = { urlInput = it },
					singleLine = true
				)
				TextButton(onClick = { onBackendUrlChanged(urlInput.trim()) }) {
					Text("Enregistrer l'URL")
				}
			}
		}

		Button(
			modifier = Modifier.fillMaxWidth(),
			enabled = !loading,
			onClick = {
				if (email.isBlank() || password.isBlank() || (showUsername && username.isBlank())) {
					return@Button
				}
				scope.launch {
					loading = true
					onSubmit(if (showUsername) username.trim() else null, email.trim(), password)
					loading = false
				}
			}
		) {
			Text(if (loading) "Chargement..." else if (showUsername) "Créer mon compte" else "Se connecter")
		}

		if (errorMessage != null) {
			Text(
				text = errorMessage,
				color = MaterialTheme.colorScheme.error,
				style = MaterialTheme.typography.bodyMedium
			)
		}
	}
}

@Composable
private fun PlaceholderPage(innerPadding: androidx.compose.foundation.layout.PaddingValues, title: String, message: String) {
	Column(
		modifier = Modifier
			.padding(innerPadding)
			.fillMaxSize()
			.padding(20.dp),
		verticalArrangement = Arrangement.Center,
		horizontalAlignment = Alignment.CenterHorizontally
	) {
		Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
		Spacer(modifier = Modifier.height(8.dp))
		Text(message, style = MaterialTheme.typography.bodyMedium)
	}
}

@Composable
private fun ProfileScreen(
	innerPadding: androidx.compose.foundation.layout.PaddingValues,
	session: AppSession,
	onLogout: () -> Unit
) {
	Column(
		modifier = Modifier
			.padding(innerPadding)
			.fillMaxSize()
			.padding(20.dp),
		verticalArrangement = Arrangement.spacedBy(12.dp)
	) {
		Text("Profil", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
		Text("Utilisateur: ${session.username ?: "Inconnu"}")
		Text("Email: ${session.email ?: "Inconnu"}")
		Text("User ID: ${session.userId ?: "Inconnu"}")
		Spacer(Modifier.height(8.dp))
		Button(onClick = onLogout) {
			Text("Se déconnecter")
		}
	}
}

@Composable
private fun SettingsScreen(
	backendUrl: String,
	musicEnabled: Boolean,
	onMusicEnabledChanged: (Boolean) -> Unit,
	onClose: () -> Unit,
	onSave: (String) -> Unit
) {
	var url by rememberSaveable(backendUrl) { mutableStateOf(backendUrl) }

	androidx.compose.material3.AlertDialog(
		onDismissRequest = onClose,
		confirmButton = {
			Button(onClick = { onSave(url.trim()) }) {
				Text("Enregistrer")
			}
		},
		dismissButton = {
			TextButton(onClick = onClose) { Text("Annuler") }
		},
		title = { Text("Paramètres") },
		text = {
			Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
				Text("URL backend")
				OutlinedTextField(
					value = url,
					onValueChange = { url = it },
					modifier = Modifier.fillMaxWidth(),
					singleLine = true
				)
				Row(
					modifier = Modifier.fillMaxWidth(),
					horizontalArrangement = Arrangement.SpaceBetween,
					verticalAlignment = Alignment.CenterVertically
				) {
					Text("Musique de fond")
					Switch(
						checked = musicEnabled,
						onCheckedChange = onMusicEnabledChanged
					)
				}
			}
		}
	)
}

private fun Throwable.toReadableError(): String {
	if (this is HttpException) {
		return when (code()) {
			401, 403 -> "Email ou mot de passe incorrect."
			409 -> "Email ou nom d'utilisateur déjà utilisé."
			else -> "Erreur serveur (${code()})."
		}
	}
	if (this is IOException) return "Impossible de joindre le serveur."
	return message ?: "Une erreur est survenue."
}
