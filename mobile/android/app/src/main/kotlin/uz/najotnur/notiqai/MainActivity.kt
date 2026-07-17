package uz.najotnur.notiqai

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter engine and the security platform channel.
 *
 * On every window attach (and on the first onCreate) we set
 * [WindowManager.LayoutParams.FLAG_SECURE] so the OS refuses to render this
 * window into screenshots, screen recordings, MediaProjection sessions or the
 * recents thumbnail. This is the same mechanism used by banking / DRM apps.
 *
 * The `notiqai/security` channel lets Dart:
 *  - toggle FLAG_SECURE at runtime (e.g. only protect authenticated screens);
 *  - query the current capture state (display flags);
 *  - be notified when the user lowers the app to a non-secure state.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "notiqai/security"
    private var channel: MethodChannel? = null
    private var secureEnabled: Boolean = false
    private var displayManager: DisplayManager? = null
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {}
        override fun onDisplayRemoved(displayId: Int) {}
        override fun onDisplayChanged(displayId: Int) {
            // Re-apply the secure flag in case the activity was reused for an
            // external display (Android Auto, Cast, …) which would otherwise
            // bypass FLAG_SECURE.
            applySecureFlag()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applySecureFlag()
    }

    override fun onResume() {
        super.onResume()
        applySecureFlag()
        displayManager = getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        displayManager?.registerDisplayListener(displayListener, null)
    }

    override fun onPause() {
        super.onPause()
        displayManager?.unregisterDisplayListener(displayListener)
        displayManager = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    secureEnabled = enabled
                    applySecureFlag()
                    result.success(secureEnabled)
                }
                "isSecure" -> result.success(secureEnabled)
                "isCaptured" -> result.success(isDisplayCaptured())
                "isRooted" -> result.success(detectRootIndicators())
                "getDeviceInfo" -> result.success(deviceInfoMap())
                else -> result.notImplemented()
            }
        }
    }

    private fun applySecureFlag() {
        runOnUiThread {
            try {
                val window = window ?: return@runOnUiThread
                if (secureEnabled) {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
            } catch (t: Throwable) {
                Log.w("NotiqAiSecurity", "applySecureFlag failed", t)
            }
        }
    }

    /**
     * Returns true if any active display is currently flagged as
     * FLAG_SECURE-bypassing (HDMI mirroring, wireless display, etc.).
     */
    private fun isDisplayCaptured(): Boolean {
        return try {
            val dm = displayManager ?: getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
            val displays: Array<Display> = dm?.getDisplays() ?: return false
            displays.any { d ->
                (d.flags and Display.FLAG_SECURE) == 0 &&
                    (d.flags and Display.FLAG_PRESENTATION) != 0
            }
        } catch (t: Throwable) {
            false
        }
    }

    private fun detectRootIndicators(): Boolean {
        val paths = arrayOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/system/sd/xbin/su", "/data/local/xbin/su", "/data/local/bin/su"
        )
        if (paths.any { java.io.File(it).exists() }) return true
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun deviceInfoMap(): Map<String, Any?> = mapOf(
        "platform" to "android",
        "os_version" to Build.VERSION.RELEASE,
        "sdk_int" to Build.VERSION.SDK_INT,
        "device_model" to Build.MODEL,
        "device_manufacturer" to Build.MANUFACTURER,
        "hardware" to Build.HARDWARE,
    )
}
