package com.ramen.ramen

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.util.concurrent.ConcurrentHashMap

class RamenBackgroundService : Service() {
    companion object {
        private const val TAG = "RamenBgService"
        private const val PROGRESS_CHANNEL_ID = "ramen_bg_progress"
        private const val ALERT_CHANNEL_ID = "ramen_bg_alerts"
        private const val FOREGROUND_NOTIFICATION_ID = 4101

        private const val ACTION_SYNC = "com.ramen.ramen.action.SYNC_BG"
        private const val ACTION_STOP = "com.ramen.ramen.action.STOP_BG"

        @Volatile
        var enableBackgroundProcessing: Boolean = true

        @Volatile
        var enableBackgroundNotifications: Boolean = true

        @Volatile
        var isActivityInForeground: Boolean = true

        private data class DownloadProgressInfo(
            val title: String,
            val progress: Double,
            val speed: String
        )

        private val activeDownloads = ConcurrentHashMap<String, DownloadProgressInfo>()
        private var alertNotificationCounter = 4200

        fun hasActiveDownloads(): Boolean = activeDownloads.isNotEmpty()

        fun onDownloadStarted(context: Context, taskId: String, title: String) {
            activeDownloads[taskId] = DownloadProgressInfo(
                title = title,
                progress = 0.0,
                speed = "Starting..."
            )
            syncService(context)
        }

        fun onDownloadProgress(context: Context, taskId: String, progress: Double, speed: String) {
            val current = activeDownloads[taskId]
            val title = current?.title ?: "Media stream"
            activeDownloads[taskId] = DownloadProgressInfo(
                title = title,
                progress = progress,
                speed = speed.ifBlank { current?.speed ?: "" }
            )
            if (enableBackgroundNotifications || enableBackgroundProcessing) {
                syncService(context)
            }
        }

        fun onDownloadFinished(
            context: Context,
            taskId: String,
            succeeded: Boolean,
            errorMsg: String? = null
        ) {
            val info = activeDownloads.remove(taskId)
            val isCancelled = errorMsg?.contains("Cancel", ignoreCase = true) == true
            if (enableBackgroundNotifications && info != null && !isCancelled) {
                if (succeeded) {
                    postCompletionAlert(
                        context,
                        title = "Download Complete",
                        body = info.title,
                        isError = false
                    )
                } else {
                    postCompletionAlert(
                        context,
                        title = "Download Failed",
                        body = errorMsg ?: info.title,
                        isError = true
                    )
                }
            }
            syncService(context)
        }

        fun syncService(context: Context) {
            try {
                val appCtx = context.applicationContext
                val nm = appCtx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                ensureChannels(nm)

                if (hasActiveDownloads()) {
                    if (enableBackgroundProcessing) {
                        val intent = Intent(appCtx, RamenBackgroundService::class.java).apply {
                            action = ACTION_SYNC
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            appCtx.startForegroundService(intent)
                        } else {
                            appCtx.startService(intent)
                        }
                    } else if (enableBackgroundNotifications) {
                        val notification = createProgressNotification(appCtx)
                        nm.notify(FOREGROUND_NOTIFICATION_ID, notification)
                    }
                } else {
                    nm.cancel(FOREGROUND_NOTIFICATION_ID)
                    val intent = Intent(appCtx, RamenBackgroundService::class.java).apply {
                        action = ACTION_STOP
                    }
                    appCtx.startService(intent)
                }
            } catch (e: Exception) {
                android.util.Log.w(TAG, "syncService notice: ${e.message}")
            }
        }

        private fun postCompletionAlert(
            context: Context,
            title: String,
            body: String,
            isError: Boolean = false
        ) {
            try {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                ensureChannels(nm)

                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, pendingFlags)

                val icon = if (isError) {
                    android.R.drawable.stat_notify_error
                } else {
                    android.R.drawable.stat_sys_download_done
                }

                val notification = NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
                    .setSmallIcon(icon)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                    .setAutoCancel(true)
                    .setContentIntent(pendingIntent)
                    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                    .build()

                nm.notify(alertNotificationCounter++, notification)
            } catch (e: Exception) {
                android.util.Log.w(TAG, "postCompletionAlert error: ${e.message}")
            }
        }

        fun createProgressNotification(context: Context): Notification {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            ensureChannels(nm)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, pendingFlags)

            val downloadCount = activeDownloads.size

            val title = if (downloadCount == 1) {
                activeDownloads.values.first().title
            } else {
                "Ramen • Downloading $downloadCount files"
            }

            val avgProgress = activeDownloads.values
                .map { it.progress.coerceIn(0.0, 100.0) }
                .average()
            val firstSpeed = activeDownloads.values.firstOrNull { it.speed.isNotBlank() }?.speed ?: ""
            val progressText = if (avgProgress > 0.0) "${String.format("%.1f", avgProgress)}%" else "Downloading..."
            val subtitle = if (firstSpeed.isNotBlank()) "$progressText • $firstSpeed" else progressText

            val avgProgressInt = avgProgress.toInt()
            val indeterminate = avgProgressInt <= 0

            return NotificationCompat.Builder(context, PROGRESS_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle(title)
                .setContentText(subtitle)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setContentIntent(pendingIntent)
                .setProgress(100, avgProgressInt, indeterminate)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        }

        private fun ensureChannels(nm: NotificationManager) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val progressChannel = NotificationChannel(
                    PROGRESS_CHANNEL_ID,
                    "Download Progress",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Active download progress"
                    setShowBadge(false)
                }
                val alertChannel = NotificationChannel(
                    ALERT_CHANNEL_ID,
                    "Download Status",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Notifications when downloads succeed or fail"
                }
                nm.createNotificationChannel(progressChannel)
                nm.createNotificationChannel(alertChannel)
            }
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var isInForeground = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForegroundServiceCleanly()
                return START_NOT_STICKY
            }
            else -> {
                if (!enableBackgroundProcessing || !hasActiveDownloads()) {
                    stopForegroundServiceCleanly()
                    return START_NOT_STICKY
                }
                acquireLocks()
                val notification = createProgressNotification(this)
                startOrUpdateForeground(notification)
            }
        }
        return START_STICKY
    }

    private fun startOrUpdateForeground(notification: Notification) {
        try {
            if (!isInForeground) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        FOREGROUND_NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    )
                } else {
                    startForeground(FOREGROUND_NOTIFICATION_ID, notification)
                }
                isInForeground = true
            } else {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(FOREGROUND_NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "startOrUpdateForeground warning: ${e.message}")
        }
    }

    @Synchronized
    private fun acquireLocks() {
        try {
            if (wakeLock == null) {
                val pm = applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Ramen:BackgroundEngineWakeLock"
                ).apply {
                    setReferenceCounted(false)
                }
            }
            if (wakeLock?.isHeld == false) {
                wakeLock?.acquire(6 * 60 * 60 * 1000L)
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "WakeLock acquire warning: ${e.message}")
        }

        try {
            if (wifiLock == null) {
                val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                @Suppress("DEPRECATION")
                val lockMode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    WifiManager.WIFI_MODE_FULL_LOW_LATENCY
                } else {
                    WifiManager.WIFI_MODE_FULL_HIGH_PERF
                }
                wifiLock = wm.createWifiLock(lockMode, "Ramen:BackgroundWifiLock").apply {
                    setReferenceCounted(false)
                }
            }
            if (wifiLock?.isHeld == false) {
                wifiLock?.acquire()
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "WifiLock acquire warning: ${e.message}")
        }
    }

    @Synchronized
    private fun releaseLocks() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}

        try {
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
            }
        } catch (_: Exception) {}
    }

    private fun stopForegroundServiceCleanly() {
        releaseLocks()
        try {
            if (isInForeground) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                isInForeground = false
            }
            stopSelf()
        } catch (e: Exception) {
            android.util.Log.w(TAG, "stopForegroundServiceCleanly warning: ${e.message}")
        }
    }

    override fun onDestroy() {
        releaseLocks()
        super.onDestroy()
    }
}
