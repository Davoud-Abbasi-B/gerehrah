package com.damostudio.gerehrah

import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != SHARE_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val text = call.argument<String>("text")
            if (text.isNullOrBlank()) {
                result.error(
                    "INVALID_SHARE_TEXT",
                    "Share text must not be empty.",
                    null,
                )
                return@setMethodCallHandler
            }

            try {
                val shareIntent =
                    Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                startActivity(Intent.createChooser(shareIntent, null))
                result.success(null)
            } catch (error: ActivityNotFoundException) {
                result.error(
                    "SHARE_UNAVAILABLE",
                    "No application is available to share text.",
                    null,
                )
            } catch (error: Exception) {
                result.error(
                    "SHARE_FAILED",
                    "Unable to open the Android share chooser.",
                    error.message,
                )
            }
        }
    }

    private companion object {
        const val SHARE_CHANNEL = "com.damostudio.gerehrah/share"
        const val SHARE_METHOD = "shareText"
    }
}
