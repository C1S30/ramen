package com.ramen.ramen

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.YoutubeDLResponse
import com.yausername.ffmpeg.FFmpeg
import com.yausername.aria2c.Aria2c

class MainActivity : FlutterActivity() {
    private val ENGINE_CHANNEL = "com.ramen.downloader/engine"
    private val STREAM_CHANNEL = "com.ramen.downloader/download_stream"

    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private val activeTasks = ConcurrentHashMap<String, String>() // taskId -> status
    private var sharedUrl: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!text.isNullOrBlank()) {
                sharedUrl = text.trim()
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup EventChannel for live download events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        // Setup MethodChannel for synchronous and asynchronous actions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "initEngine" -> {
                        executor.execute {
                            try {
                                YoutubeDL.getInstance().init(applicationContext)
                                FFmpeg.getInstance().init(applicationContext)
                                Aria2c.getInstance().init(applicationContext)
                                sendResultSuccess(result, true)
                            } catch (e: Exception) {
                                sendResultError(result, "INIT_ERROR", e.localizedMessage ?: "Failed to initialize binaries", null)
                            }
                        }
                    }

                    "getSharedUrl" -> {
                        val url = sharedUrl
                        sharedUrl = null // consume once
                        result.success(url)
                    }

                    "getEngineVersions" -> {
                        executor.execute {
                            try {
                                val ytDlpVer = YoutubeDL.getInstance().version(applicationContext) ?: "Unknown"
                                val versions = mapOf(
                                    "ytdlp" to ytDlpVer,
                                    "ffmpeg" to "Embedded NDK",
                                    "aria2c" to "Embedded NDK"
                                )
                                sendResultSuccess(result, versions)
                            } catch (e: Exception) {
                                val fallback = mapOf(
                                    "ytdlp" to "v2024.08.06",
                                    "ffmpeg" to "Embedded",
                                    "aria2c" to "Embedded"
                                )
                                sendResultSuccess(result, fallback)
                            }
                        }
                    }

                    "updateEngine" -> {
                        executor.execute {
                            try {
                                val status = YoutubeDL.getInstance().updateYoutubeDL(applicationContext)
                                val newVersion = YoutubeDL.getInstance().version(applicationContext) ?: "Updated"
                                sendResultSuccess(result, newVersion)
                            } catch (e: Exception) {
                                sendResultError(result, "UPDATE_ERROR", e.localizedMessage ?: "Failed to update engine", null)
                            }
                        }
                    }

                    "getFormats" -> {
                        val url = call.argument<String>("url")
                        val extraArgs = call.argument<List<String>>("extraArgs") ?: emptyList()

                        if (url.isNullOrBlank()) {
                            result.error("INVALID_URL", "Target URL cannot be empty", null)
                            return@setMethodCallHandler
                        }

                        executor.execute {
                            try {
                                val request = YoutubeDLRequest(url)
                                request.addOption("--dump-single-json")
                                request.addOption("--flat-playlist")
                                request.addOption("--no-warnings")
                                for (arg in extraArgs) {
                                    if (arg.isNotBlank()) {
                                        request.addOption(arg)
                                    }
                                }

                                val response: YoutubeDLResponse = YoutubeDL.getInstance().execute(request)
                                val jsonOut = response.out
                                sendResultSuccess(result, jsonOut)
                            } catch (e: Exception) {
                                sendResultError(result, "FORMAT_EXTRACTION_FAILED", e.localizedMessage ?: "Failed to fetch formats", null)
                            }
                        }
                    }

                    "startDownload" -> {
                        val taskId = call.argument<String>("taskId") ?: ""
                        val url = call.argument<String>("url") ?: ""
                        val outDir = call.argument<String>("outDir") ?: ""
                        val args = call.argument<List<String>>("args") ?: emptyList()

                        if (taskId.isBlank() || url.isBlank()) {
                            result.error("INVALID_ARGS", "taskId and url are required", null)
                            return@setMethodCallHandler
                        }

                        activeTasks[taskId] = "DOWNLOADING"
                        result.success(true)

                        executor.execute {
                            try {
                                val targetDir = if (outDir.isNotBlank()) File(outDir) else applicationContext.getExternalFilesDir(null)
                                if (targetDir != null && !targetDir.exists()) {
                                    targetDir.mkdirs()
                                }

                                val request = YoutubeDLRequest(url)
                                val outTemplate = File(targetDir, "%(title)s.%(ext)s").absolutePath
                                request.addOption("-o", outTemplate)

                                for (arg in args) {
                                    if (arg.isNotBlank()) {
                                        request.addOption(arg)
                                    }
                                }

                                YoutubeDL.getInstance().execute(request, taskId) { progress, etaInSeconds, line ->
                                    mainHandler.post {
                                        eventSink?.success(
                                            mapOf(
                                                "taskId" to taskId,
                                                "status" to "DOWNLOADING",
                                                "progress" to progress.toDouble(),
                                                "eta" to etaInSeconds,
                                                "log" to (line ?: "")
                                            )
                                        )
                                    }
                                }

                                activeTasks.remove(taskId)
                                mainHandler.post {
                                    eventSink?.success(
                                        mapOf(
                                            "taskId" to taskId,
                                            "status" to "COMPLETED",
                                            "progress" to 100.0,
                                            "eta" to 0,
                                            "log" to "Download finished successfully."
                                        )
                                    )
                                }
                            } catch (e: Exception) {
                                activeTasks.remove(taskId)
                                mainHandler.post {
                                    eventSink?.success(
                                        mapOf(
                                            "taskId" to taskId,
                                            "status" to "FAILED",
                                            "error" to (e.localizedMessage ?: "Download failed"),
                                            "log" to (e.message ?: "")
                                        )
                                    )
                                }
                            }
                        }
                    }

                    "cancelDownload" -> {
                        val taskId = call.argument<String>("taskId") ?: ""
                        if (taskId.isNotBlank()) {
                            try {
                                YoutubeDL.getInstance().destroyProcessById(taskId)
                                activeTasks.remove(taskId)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("CANCEL_FAILED", e.localizedMessage, null)
                            }
                        } else {
                            result.error("INVALID_TASK_ID", "TaskId cannot be empty", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun sendResultSuccess(result: MethodChannel.Result, data: Any?) {
        mainHandler.post {
            result.success(data)
        }
    }

    private fun sendResultError(result: MethodChannel.Result, errorCode: String, message: String?, details: Any?) {
        mainHandler.post {
            result.error(errorCode, message, details)
        }
    }
}
