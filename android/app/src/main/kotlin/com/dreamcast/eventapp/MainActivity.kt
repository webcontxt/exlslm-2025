package com.dreamcast.eventapp

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // ✅ This passes the intent to Flutter correctly
    }
}
