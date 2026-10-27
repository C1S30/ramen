package com.ramen.ramen

import android.app.Application
import android.util.Log
import com.yausername.aria2c.Aria2c
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL

class RamenApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            YoutubeDL.getInstance().init(this)
            Log.i("RamenApplication", "Embedded mobile yt-dlp initialized successfully")
        } catch (e: Exception) {
            Log.e("RamenApplication", "Failed to initialize embedded mobile yt-dlp", e)
        }

        try {
            FFmpeg.getInstance().init(this)
            Log.i("RamenApplication", "Embedded mobile FFmpeg initialized successfully")
        } catch (e: Exception) {
            Log.e("RamenApplication", "Failed to initialize embedded mobile FFmpeg", e)
        }

        try {
            Aria2c.getInstance().init(this)
            Log.i("RamenApplication", "Embedded mobile aria2c initialized successfully")
        } catch (e: Exception) {
            Log.e("RamenApplication", "Failed to initialize embedded mobile aria2c", e)
        }
    }
}
