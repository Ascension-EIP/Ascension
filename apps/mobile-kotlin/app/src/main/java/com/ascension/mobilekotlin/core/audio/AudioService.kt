package com.ascension.mobilekotlin.core.audio

import android.content.Context
import android.media.MediaPlayer

class AudioService private constructor(private val context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private var player: MediaPlayer? = null

    var musicEnabled: Boolean = false
        private set

    fun init() {
        musicEnabled = prefs.getBoolean(KEY_MUSIC_ENABLED, false)
        ensurePlayer()
        if (musicEnabled) {
            player?.start()
        }
    }

    fun setMusicEnabled(enabled: Boolean) {
        musicEnabled = enabled
        prefs.edit().putBoolean(KEY_MUSIC_ENABLED, enabled).apply()

        ensurePlayer()
        if (enabled) {
            player?.start()
        } else {
            player?.pause()
        }
    }

    fun release() {
        player?.release()
        player = null
    }

    private fun ensurePlayer() {
        if (player != null) return

        val assetFile = context.assets.openFd("audio/ascension.mp3")
        player = MediaPlayer().apply {
            setDataSource(assetFile.fileDescriptor, assetFile.startOffset, assetFile.length)
            isLooping = true
            setVolume(0.4f, 0.4f)
            prepare()
        }
        assetFile.close()
    }

    companion object {
        private const val PREFS_NAME = "ascension_prefs"
        private const val KEY_MUSIC_ENABLED = "music_enabled"

        @Volatile
        private var instance: AudioService? = null

        fun getInstance(context: Context): AudioService {
            return instance ?: synchronized(this) {
                instance ?: AudioService(context.applicationContext).also { instance = it }
            }
        }
    }
}
