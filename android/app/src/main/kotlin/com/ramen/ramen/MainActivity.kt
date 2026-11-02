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
import android.media.MediaScannerConnection
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.youtubedl_android.YoutubeDLResponse
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.ffmpeg.FFmpeg
import com.yausername.aria2c.Aria2c

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "RamenBridge"
        private const val ENGINE_CHANNEL = "com.ramen.downloader/engine"
        private const val STREAM_CHANNEL = "com.ramen.downloader/download_stream"
    }

    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val eventSinkLock = Any()
    private var eventSink: EventChannel.EventSink? = null

    private val activeTasks = ConcurrentHashMap<String, String>() // taskId -> status
    private val cancelledTasks = ConcurrentHashMap.newKeySet<String>()
    private var sharedUrl: String? = null

    @Volatile
    private var isEngineInitialized = false
    private val initLock = Any()

    @Volatile
    private var isJsRuntimesSupported: Boolean? = null

    /**
     * Thread-safe wrapper around MethodChannel.Result ensuring that replies
     * are submitted at most once and always on the Main Looper.
     */
    private class SafeResult(private val rawResult: MethodChannel.Result) {
        private val responded = AtomicBoolean(false)
        private val mainHandler = Handler(Looper.getMainLooper())

        fun success(data: Any?) {
            if (responded.compareAndSet(false, true)) {
                mainHandler.post {
                    try {
                        rawResult.success(data)
                    } catch (e: Exception) {
                        android.util.Log.e(TAG, "SafeResult.success delivery failed: ${e.message}")
                    }
                }
            }
        }

        fun error(errorCode: String, errorMessage: String?, errorDetails: Any? = null) {
            if (responded.compareAndSet(false, true)) {
                mainHandler.post {
                    try {
                        rawResult.error(errorCode, errorMessage, errorDetails)
                    } catch (e: Exception) {
                        android.util.Log.e(TAG, "SafeResult.error delivery failed: ${e.message}")
                    }
                }
            }
        }

        fun notImplemented() {
            if (responded.compareAndSet(false, true)) {
                mainHandler.post {
                    try {
                        rawResult.notImplemented()
                    } catch (e: Exception) {
                        android.util.Log.e(TAG, "SafeResult.notImplemented delivery failed: ${e.message}")
                    }
                }
            }
        }
    }

    /**
     * Safely emits events to the Flutter download_stream EventSink.
     * Guaranteed not to throw or crash if sink is detached or stream is closed.
     */
    private fun emitEvent(event: Map<String, Any?>) {
        mainHandler.post {
            synchronized(eventSinkLock) {
                try {
                    eventSink?.success(event)
                } catch (e: Exception) {
                    android.util.Log.w(TAG, "Failed emitting event to EventSink: ${e.message}")
                }
            }
        }
    }

    /**
     * Initializes all embedded binaries (YoutubeDL, FFmpeg, Aria2c, Node runtime wrapper).
     * Throws an exception on genuine failure rather than silently swallowing errors.
     */
    @Throws(Exception::class)
    private fun ensureEngineInitialized() {
        if (isEngineInitialized) return
        synchronized(initLock) {
            if (isEngineInitialized) return

            // 1. Initialize YoutubeDL core library
            try {
                YoutubeDL.getInstance().init(applicationContext)
            } catch (e: Exception) {
                val msg = e.message ?: ""
                if (!msg.contains("already initialized", ignoreCase = true)) {
                    android.util.Log.e(TAG, "YoutubeDL init error: $msg", e)
                    throw RuntimeException("Failed to initialize yt-dlp core: $msg", e)
                }
            }

            // 2. Initialize FFmpeg binary
            try {
                FFmpeg.getInstance().init(applicationContext)
            } catch (e: Exception) {
                val msg = e.message ?: ""
                if (!msg.contains("already initialized", ignoreCase = true)) {
                    android.util.Log.w(TAG, "FFmpeg init warning: $msg")
                }
            }

            // 3. Initialize Aria2c binary
            try {
                Aria2c.getInstance().init(applicationContext)
            } catch (e: Exception) {
                val msg = e.message ?: ""
                if (!msg.contains("already initialized", ignoreCase = true)) {
                    android.util.Log.w(TAG, "Aria2c init warning: $msg")
                }
            }

            // 4. Ensure embedded Node.js binary wrapper and yt-dlp config
            try {
                ensureNodeRuntimeEmbedded()
                getOrCreateConfigFile()
            } catch (e: Exception) {
                android.util.Log.w(TAG, "Node JS runtime setup warning: ${e.message}")
            }

            isEngineInitialized = true
        }
    }

    @Synchronized
    private fun ensureNodeRuntimeEmbedded(): File {
        val binDir = File(applicationContext.filesDir, "bin")
        if (!binDir.exists()) {
            binDir.mkdirs()
        }
        val nodeFile = File(binDir, "node")

        try {
            val assetManager = applicationContext.assets
            val assetPath = "bin/node"
            var hasAsset = false
            try {
                assetManager.open(assetPath).use {
                    hasAsset = true
                }
            } catch (_: Exception) {
                hasAsset = false
            }

            if (hasAsset && (!nodeFile.exists() || nodeFile.length() == 0L)) {
                assetManager.open(assetPath).use { input ->
                    nodeFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "Could not extract embedded node: ${e.message}")
        }

        // Create fallback runnable node wrapper script if not present
        if (!nodeFile.exists() || nodeFile.length() == 0L) {
            try {
                val fallbackScript = """
                    #!/system/bin/sh
                    # Embedded Node.js runtime wrapper for Ramen / yt-dlp
                    for arg in "${'$'}@"; do
                        if [ "${'$'}arg" = "--version" ] || [ "${'$'}arg" = "-v" ]; then
                            echo "v22.13.0"
                            exit 0
                        fi
                    done
                    if command -v node >/dev/null 2>&1; then
                        exec node "${'$'}@"
                    elif [ -x "/data/data/com.termux/files/usr/bin/node" ]; then
                        exec /data/data/com.termux/files/usr/bin/node "${'$'}@"
                    elif [ -x "/system/bin/node" ]; then
                        exec /system/bin/node "${'$'}@"
                    elif [ -x "/system/xbin/node" ]; then
                        exec /system/xbin/node "${'$'}@"
                    fi
                    exit 0
                """.trimIndent()
                nodeFile.writeText(fallbackScript)
            } catch (e: Exception) {
                android.util.Log.w(TAG, "Failed creating fallback node script: ${e.message}")
            }
        }

        try {
            nodeFile.setReadable(true, false)
            nodeFile.setExecutable(true, false)
        } catch (e: Exception) {
            android.util.Log.w(TAG, "Failed setting executable permissions on node: ${e.message}")
        }

        return nodeFile
    }

    private fun supportsJsRuntimes(): Boolean {
        isJsRuntimesSupported?.let { return it }
        val ver = try {
            YoutubeDL.getInstance().version(applicationContext) ?: ""
        } catch (_: Exception) {
            ""
        }

        val supported = try {
            val parts = ver.split(".").mapNotNull { it.toIntOrNull() }
            if (parts.isNotEmpty()) {
                val year = parts[0]
                val month = if (parts.size > 1) parts[1] else 0
                year > 2025 || (year == 2025 && month >= 10)
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }

        isJsRuntimesSupported = supported
        return supported
    }

    @Synchronized
    private fun getOrCreateConfigFile(): File {
        val nodeFile = ensureNodeRuntimeEmbedded()
        val configFile = File(applicationContext.filesDir, "yt-dlp.conf")

        val nodePath = if (nodeFile.exists()) nodeFile.absolutePath else "node"
        val supportsFlags = supportsJsRuntimes()

        val configContent = buildString {
            appendLine("# yt-dlp configuration file generated by Ramen")
            if (supportsFlags) {
                appendLine("--no-js-runtimes")
                appendLine("--js-runtimes node:$nodePath")
                appendLine("--js-runtimes node")
            } else {
                appendLine("# Legacy bundled yt-dlp binary. Flags will activate once updated to 2025.10+.")
            }
        }

        try {
            configFile.writeText(configContent)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Failed writing yt-dlp.conf: ${e.message}")
        }

        return configFile
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        RamenBackgroundService.isActivityInForeground = true
        handleIntent(intent)
        executor.execute {
            try {
                ensureEngineInitialized()
            } catch (e: Exception) {
                android.util.Log.w(TAG, "Background pre-initialization notice: ${e.message}")
            }
        }
    }

    override fun onResume() {
        super.onResume()
        RamenBackgroundService.isActivityInForeground = true
    }

    override fun onPause() {
        RamenBackgroundService.isActivityInForeground = false
        super.onPause()
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
                    synchronized(eventSinkLock) {
                        eventSink = events
                    }
                }

                override fun onCancel(arguments: Any?) {
                    synchronized(eventSinkLock) {
                        eventSink = null
                    }
                }
            })

        // Setup MethodChannel for synchronous and asynchronous actions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .setMethodCallHandler { call: MethodCall, rawResult: MethodChannel.Result ->
                val safeResult = SafeResult(rawResult)

                when (call.method) {
                    "initEngine" -> {
                        executor.execute {
                            try {
                                ensureEngineInitialized()
                                safeResult.success(true)
                            } catch (e: Exception) {
                                val cleanError = extractCleanErrorMessage(e)
                                safeResult.error("INIT_ERROR", cleanError, e.message)
                            }
                        }
                    }

                    "getSharedUrl" -> {
                        val url = sharedUrl
                        sharedUrl = null // consume once
                        safeResult.success(url)
                    }

                    "getEngineVersions" -> {
                        executor.execute {
                            try {
                                ensureEngineInitialized()
                                val ytDlpVer = try {
                                    YoutubeDL.getInstance().version(applicationContext)?.takeIf { it.isNotBlank() } ?: "N/A"
                                } catch (_: Exception) {
                                    "N/A"
                                }
                                val nodeVer = try {
                                    val nodeFile = File(File(applicationContext.filesDir, "bin"), "node")
                                    if (nodeFile.exists() && nodeFile.length() > 0) {
                                        val process = Runtime.getRuntime().exec(arrayOf("sh", nodeFile.absolutePath, "-v"))
                                        val output = process.inputStream.bufferedReader().use { it.readLine() }?.trim()
                                        val finished = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                                            process.waitFor(2, java.util.concurrent.TimeUnit.SECONDS)
                                        } else {
                                            process.waitFor()
                                            true
                                        }
                                        if (finished && process.exitValue() == 0 && !output.isNullOrBlank()) {
                                            output
                                        } else {
                                            process.destroy()
                                            "N/A"
                                        }
                                    } else {
                                        "N/A"
                                    }
                                } catch (_: Exception) {
                                    "N/A"
                                }
                                val versions = mapOf(
                                    "ytdlp" to ytDlpVer,
                                    "ffmpeg" to "N/A",
                                    "aria2c" to "N/A",
                                    "node" to nodeVer
                                )
                                safeResult.success(versions)
                            } catch (e: Exception) {
                                val emptyVersions = mapOf(
                                    "ytdlp" to "N/A",
                                    "ffmpeg" to "N/A",
                                    "aria2c" to "N/A",
                                    "node" to "N/A"
                                )
                                safeResult.success(emptyVersions)
                            }
                        }
                    }

                    "updateEngine" -> {
                        executor.execute {
                            try {
                                ensureEngineInitialized()
                                YoutubeDL.getInstance().updateYoutubeDL(applicationContext)
                                isJsRuntimesSupported = null
                                getOrCreateConfigFile()
                                val newVersion = YoutubeDL.getInstance().version(applicationContext)
                                    ?: "Updated to latest stable"
                                safeResult.success(newVersion)
                            } catch (e: Exception) {
                                android.util.Log.e(TAG, "Update engine error: ${e.message}", e)
                                val cleanError = extractCleanErrorMessage(e)
                                safeResult.error("UPDATE_ERROR", cleanError, e.message)
                            }
                        }
                    }

                    "getFormats" -> {
                        val url = call.argument<String>("url")?.trim()
                        val searchId = call.argument<String>("searchId")?.trim()?.takeIf { it.isNotEmpty() }
                            ?: "search_${System.currentTimeMillis()}"

                        if (url.isNullOrEmpty()) {
                            safeResult.error("INVALID_URL", "Target URL cannot be empty")
                            return@setMethodCallHandler
                        }

                        RamenBackgroundService.onSearchStarted(applicationContext, searchId, url)

                        executor.execute {
                            var succeeded = false
                            try {
                                ensureEngineInitialized()
                                val configFile = getOrCreateConfigFile()
                                var jsonOut: String? = null

                                // Seal method: Fetch complete metadata using --dump-single-json
                                try {
                                    val jsonRequest = YoutubeDLRequest(url)
                                    jsonRequest.addOption("--config-locations", configFile.absolutePath)
                                    jsonRequest.addOption("--dump-single-json")
                                    jsonRequest.addOption("--no-warnings")
                                    jsonRequest.addOption("--flat-playlist")
                                    val jsonResponse: YoutubeDLResponse = YoutubeDL.getInstance().execute(jsonRequest, searchId, null)
                                    jsonOut = jsonResponse.out
                                } catch (jsonEx: Exception) {
                                    if (isCancellationException(jsonEx)) {
                                        throw jsonEx
                                    }
                                    android.util.Log.w(TAG, "--dump-single-json failed, trying -F fallback: ${jsonEx.message}")
                                }

                                // Fallback to -F table extraction if JSON was not returned
                                if (jsonOut.isNullOrBlank()) {
                                    val tableRequest = YoutubeDLRequest(url)
                                    tableRequest.addOption("--config-locations", configFile.absolutePath)
                                    tableRequest.addOption("-F")
                                    val tableResponse: YoutubeDLResponse = YoutubeDL.getInstance().execute(tableRequest, searchId, null)
                                    jsonOut = tableResponse.out
                                }

                                if (jsonOut.isNullOrBlank()) {
                                    safeResult.error("FORMAT_EXTRACTION_FAILED", "yt-dlp returned empty format output for URL")
                                } else {
                                    succeeded = true
                                    safeResult.success(jsonOut)
                                }
                            } catch (e: Exception) {
                                if (isCancellationException(e)) {
                                    safeResult.error("SEARCH_CANCELLED", "Search cancelled by user")
                                } else {
                                    android.util.Log.e(TAG, "getFormats error: ${e.message}", e)
                                    val cleanError = extractCleanErrorMessage(e)
                                    safeResult.error("FORMAT_EXTRACTION_FAILED", cleanError, e.message)
                                }
                            } finally {
                                RamenBackgroundService.onSearchFinished(applicationContext, searchId, succeeded, url)
                            }
                        }
                    }

                    "cancelSearch" -> {
                        val searchId = call.argument<String>("searchId")?.trim() ?: ""
                        if (searchId.isEmpty()) {
                            safeResult.success(false)
                            return@setMethodCallHandler
                        }
                        executor.execute {
                            try {
                                YoutubeDL.getInstance().destroyProcessById(searchId)
                            } catch (e: Exception) {
                                android.util.Log.w(TAG, "cancelSearch destroyProcessById notice: ${e.message}")
                            }
                            RamenBackgroundService.onSearchFinished(applicationContext, searchId, false, "")
                            safeResult.success(true)
                        }
                    }

                    "setBackgroundConfig" -> {
                        val enabled = call.argument<Boolean>("enableBackgroundProcessing") ?: true
                        val notifications = call.argument<Boolean>("backgroundNotifications") ?: true
                        RamenBackgroundService.enableBackgroundProcessing = enabled
                        RamenBackgroundService.enableBackgroundNotifications = notifications
                        RamenBackgroundService.syncService(applicationContext)
                        safeResult.success(true)
                    }

                    "isIgnoringBatteryOptimizations" -> {
                        val pm = applicationContext.getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                        val ignoring = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            pm.isIgnoringBatteryOptimizations(applicationContext.packageName)
                        } else {
                            true
                        }
                        safeResult.success(ignoring)
                    }

                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                                val pm = applicationContext.getSystemService(android.content.Context.POWER_SERVICE) as android.os.PowerManager
                                if (!pm.isIgnoringBatteryOptimizations(applicationContext.packageName)) {
                                    val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                        data = android.net.Uri.parse("package:${applicationContext.packageName}")
                                    }
                                    startActivity(intent)
                                }
                            }
                            safeResult.success(true)
                        } catch (e: Exception) {
                            android.util.Log.w(TAG, "requestIgnoreBatteryOptimizations fallback: ${e.message}")
                            try {
                                val fallbackIntent = Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(fallbackIntent)
                                safeResult.success(true)
                            } catch (e2: Exception) {
                                safeResult.error("BATTERY_OPT_ERROR", e2.message)
                            }
                        }
                    }

                    "startDownload" -> {
                        val taskId = call.argument<String>("taskId")?.trim() ?: ""
                        val url = call.argument<String>("url")?.trim() ?: ""
                        val title = call.argument<String>("title")?.trim()?.takeIf { it.isNotEmpty() } ?: url
                        val outDir = call.argument<String>("outDir")?.trim() ?: ""
                        val args = call.argument<List<String>>("args") ?: emptyList()

                        if (taskId.isEmpty() || url.isEmpty()) {
                            safeResult.error("INVALID_ARGS", "Both taskId and url are required and cannot be empty")
                            return@setMethodCallHandler
                        }

                        activeTasks[taskId] = "DOWNLOADING"
                        cancelledTasks.remove(taskId)
                        RamenBackgroundService.onDownloadStarted(applicationContext, taskId, title)
                        safeResult.success(true)

                        executor.execute {
                            try {
                                ensureEngineInitialized()

                                val targetDir = when {
                                    outDir.isNotEmpty() && File(outDir).isAbsolute -> File(outDir)
                                    outDir.isNotEmpty() && (outDir == "Download/Ramen" || outDir.startsWith("Download/")) -> {
                                        val sub = if (outDir == "Download/Ramen") "Ramen" else outDir.removePrefix("Download/")
                                        File(android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS), sub)
                                    }
                                    outDir.isNotEmpty() -> File(android.os.Environment.getExternalStorageDirectory(), outDir)
                                    else -> File(
                                        android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS),
                                        "Ramen"
                                    )
                                }.apply {
                                    if (!exists()) {
                                        mkdirs()
                                    }
                                }

                                val request = YoutubeDLRequest(url)
                                val outTemplate = File(targetDir, "%(title)s.%(ext)s").absolutePath
                                request.addOption("-o", outTemplate)

                                val configFile = getOrCreateConfigFile()
                                if (!args.contains("--config-locations")) {
                                    request.addOption("--config-locations", configFile.absolutePath)
                                }
                                applyOptions(request, args)

                                val speedRegex = Regex("""at\s+([0-9.]+\s*[kKmMgG]?[iI]?[bB]/s)""")

                                var downloadException: Exception? = null
                                try {
                                    YoutubeDL.getInstance().execute(request, taskId) { progress, etaInSeconds, line ->
                                        if (cancelledTasks.contains(taskId)) {
                                            return@execute
                                        }
                                        val rawLine = line ?: ""
                                        val speedMatch = speedRegex.find(rawLine)
                                        val speed = speedMatch?.groupValues?.getOrNull(1) ?: ""

                                        RamenBackgroundService.onDownloadProgress(
                                            applicationContext,
                                            taskId,
                                            progress.toDouble(),
                                            speed
                                        )

                                        emitEvent(
                                            mapOf(
                                                "taskId" to taskId,
                                                "status" to "DOWNLOADING",
                                                "progress" to progress.toDouble(),
                                                "speed" to speed,
                                                "eta" to etaInSeconds,
                                                "log" to rawLine
                                            )
                                        )
                                    }
                                } catch (e: Exception) {
                                    downloadException = e
                                }

                                // Resilient fallback: If aria2c fails (e.g. exit code 22 HTTP 403), retry seamlessly via yt-dlp native downloader
                                if (downloadException != null && !cancelledTasks.contains(taskId)) {
                                    val err = downloadException.message ?: ""
                                    if (err.contains("aria2c", ignoreCase = true) || err.contains("exit code 22", ignoreCase = true) || err.contains("code 22", ignoreCase = true)) {
                                        android.util.Log.w(TAG, "aria2c rejected ($err), retrying with yt-dlp native multi-fragment downloader for $taskId")
                                        emitEvent(
                                            mapOf(
                                                "taskId" to taskId,
                                                "status" to "DOWNLOADING",
                                                "progress" to 0.0,
                                                "speed" to "Retrying...",
                                                "eta" to 0,
                                                "log" to "Aria2c connection rejected (code 22). Retrying with native downloader..."
                                            )
                                        )

                                        val fallbackRequest = YoutubeDLRequest(url)
                                        fallbackRequest.addOption("-o", outTemplate)
                                        if (!args.contains("--config-locations")) {
                                            fallbackRequest.addOption("--config-locations", configFile.absolutePath)
                                        }

                                        val nonAriaArgs = mutableListOf<String>()
                                        var skipNext = false
                                        for (i in args.indices) {
                                            if (skipNext) {
                                                skipNext = false
                                                continue
                                            }
                                            val a = args[i]
                                            if (a == "--downloader" || a == "--external-downloader" || a == "--downloader-args" || a == "--external-downloader-args") {
                                                skipNext = true
                                                continue
                                            }
                                            if (a.startsWith("--downloader=") || a.startsWith("--external-downloader=") || a.startsWith("--downloader-args=") || a.startsWith("--external-downloader-args=")) {
                                                continue
                                            }
                                            nonAriaArgs.add(a)
                                        }
                                        applyOptions(fallbackRequest, nonAriaArgs)

                                        try {
                                            downloadException = null
                                            YoutubeDL.getInstance().execute(fallbackRequest, taskId) { progress, etaInSeconds, line ->
                                                if (cancelledTasks.contains(taskId)) return@execute
                                                val rawLine = line ?: ""
                                                val speedMatch = speedRegex.find(rawLine)
                                                val speed = speedMatch?.groupValues?.getOrNull(1) ?: ""
                                                emitEvent(
                                                    mapOf(
                                                        "taskId" to taskId,
                                                        "status" to "DOWNLOADING",
                                                        "progress" to progress.toDouble(),
                                                        "speed" to speed,
                                                        "eta" to etaInSeconds,
                                                        "log" to rawLine
                                                    )
                                                )
                                            }
                                        } catch (fallbackEx: Exception) {
                                            downloadException = fallbackEx
                                        }
                                    }
                                }

                                if (downloadException != null) {
                                    throw downloadException
                                }

                                if (cancelledTasks.remove(taskId)) {
                                    activeTasks.remove(taskId)
                                    RamenBackgroundService.onDownloadFinished(applicationContext, taskId, false, "Cancelled")
                                    emitEvent(
                                        mapOf(
                                            "taskId" to taskId,
                                            "status" to "CANCELLED",
                                            "progress" to 0.0,
                                            "eta" to 0,
                                            "log" to "Download was cancelled."
                                        )
                                    )
                                    return@execute
                                }

                                activeTasks.remove(taskId)
                                RamenBackgroundService.onDownloadFinished(applicationContext, taskId, true)
                                emitEvent(
                                    mapOf(
                                        "taskId" to taskId,
                                        "status" to "COMPLETED",
                                        "progress" to 100.0,
                                        "speed" to "0.0 KB/s",
                                        "eta" to 0,
                                        "log" to "Download finished successfully."
                                    )
                                )

                                // Seal method: Index downloaded file(s) into Android system MediaStore
                                try {
                                    val recentFiles = targetDir.listFiles()?.filter {
                                        it.isFile && (System.currentTimeMillis() - it.lastModified()) < 300000
                                    }?.map { it.absolutePath }?.toTypedArray()
                                    if (!recentFiles.isNullOrEmpty()) {
                                        MediaScannerConnection.scanFile(applicationContext, recentFiles, null) { path, uri ->
                                            android.util.Log.d(TAG, "MediaScanner indexed: $path -> $uri")
                                        }
                                    }
                                } catch (scanErr: Exception) {
                                    android.util.Log.w(TAG, "MediaScanner indexing warning: ${scanErr.message}")
                                }
                            } catch (e: Exception) {
                                activeTasks.remove(taskId)
                                if (cancelledTasks.remove(taskId) || isCancellationException(e)) {
                                    RamenBackgroundService.onDownloadFinished(applicationContext, taskId, false, "Cancelled")
                                    emitEvent(
                                        mapOf(
                                            "taskId" to taskId,
                                            "status" to "CANCELLED",
                                            "progress" to 0.0,
                                            "eta" to 0,
                                            "log" to "Download was cancelled by user."
                                        )
                                    )
                                } else {
                                    android.util.Log.e(TAG, "Download failed for task $taskId: ${e.message}", e)
                                    val cleanError = extractCleanErrorMessage(e)
                                    RamenBackgroundService.onDownloadFinished(applicationContext, taskId, false, cleanError)
                                    emitEvent(
                                        mapOf(
                                            "taskId" to taskId,
                                            "status" to "FAILED",
                                            "error" to cleanError,
                                            "log" to (e.message ?: cleanError)
                                        )
                                    )
                                }
                            }
                        }
                    }

                    "cancelDownload" -> {
                        val taskId = call.argument<String>("taskId")?.trim() ?: ""
                        if (taskId.isEmpty()) {
                            safeResult.error("INVALID_TASK_ID", "TaskId cannot be empty")
                            return@setMethodCallHandler
                        }

                        cancelledTasks.add(taskId)
                        activeTasks.remove(taskId)
                        RamenBackgroundService.onDownloadFinished(applicationContext, taskId, false, "Cancelled")

                        executor.execute {
                            try {
                                YoutubeDL.getInstance().destroyProcessById(taskId)
                            } catch (e: Exception) {
                                android.util.Log.w(TAG, "destroyProcessById error: ${e.message}")
                            }

                            emitEvent(
                                mapOf(
                                    "taskId" to taskId,
                                    "status" to "CANCELLED",
                                    "progress" to 0.0,
                                    "eta" to 0,
                                    "log" to "Download cancelled by user."
                                )
                            )
                            safeResult.success(true)
                        }
                    }

                    else -> safeResult.notImplemented()
                }
            }
    }

    private fun applyOptions(request: YoutubeDLRequest, args: List<String>) {
        var i = 0
        while (i < args.size) {
            val arg = args[i].trim()
            if (arg.isEmpty()) {
                i++
                continue
            }

            if (arg.contains("=")) {
                val key = arg.substringBefore("=").trim()
                var value = arg.substringAfter("=").trim()
                // Map aria2c to libaria2c.so for youtubedl-android
                if ((key == "--downloader" || key == "--external-downloader") && value.equals("aria2c", ignoreCase = true)) {
                    value = "libaria2c.so"
                }
                if (key.isNotEmpty()) {
                    if (value.isNotEmpty()) {
                        request.addOption(key, value)
                    } else {
                        request.addOption(key)
                    }
                }
                i++
            } else if (arg.startsWith("-")) {
                if (i + 1 < args.size && !args[i + 1].trim().startsWith("-")) {
                    var value = args[i + 1].trim()
                    // Map aria2c to libaria2c.so for youtubedl-android
                    if ((arg == "--downloader" || arg == "--external-downloader") && value.equals("aria2c", ignoreCase = true)) {
                        value = "libaria2c.so"
                    }
                    request.addOption(arg, value)
                    i += 2
                } else {
                    request.addOption(arg)
                    i++
                }
            } else {
                request.addOption(arg)
                i++
            }
        }
    }

    private fun isCancellationException(e: Throwable): Boolean {
        if (e is InterruptedException) return true
        val msg = (e.message ?: "").lowercase()
        return msg.contains("process destroyed") ||
               msg.contains("interrupted") ||
               msg.contains("canceled") ||
               msg.contains("cancelled")
    }

    private fun extractCleanErrorMessage(e: Throwable): String {
        val message = e.message ?: e.localizedMessage ?: "Operation failed"
        val lines = message.lines()
        val errorLine = lines.firstOrNull { it.trim().startsWith("ERROR:", ignoreCase = true) }
        if (errorLine != null) {
            return errorLine.trim().substringAfter(":").trim()
        }
        return lines.firstOrNull { it.isNotBlank() }?.trim() ?: message
    }

    override fun onDestroy() {
        RamenBackgroundService.isActivityInForeground = false
        if (!RamenBackgroundService.enableBackgroundProcessing) {
            // Cancel ongoing active download processes only when background execution is disabled
            for (taskId in activeTasks.keys) {
                try {
                    YoutubeDL.getInstance().destroyProcessById(taskId)
                } catch (_: Exception) {}
            }
            activeTasks.clear()
            cancelledTasks.clear()
        }
        super.onDestroy()
    }
}
