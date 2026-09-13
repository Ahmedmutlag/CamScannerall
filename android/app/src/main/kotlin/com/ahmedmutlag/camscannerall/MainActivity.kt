package com.ahmedmutlag.camscannerall

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Bridges the native "Scan document" Quick Settings Tile (see
/// ScanTileService) to the Flutter side. The tile launches this activity
/// with [ACTION_OPEN_SCANNER]; Flutter pulls that pending action once its
/// own channel handler is ready (see lib/services/quick_tile_channel.dart)
/// instead of relying on a native push, which would race the engine boot.
///
/// Extends FlutterFragmentActivity (not plain FlutterActivity) because the
/// local_auth plugin's biometric prompt is an androidx Fragment dialog and
/// silently fails to show on a non-FragmentActivity host.
class MainActivity : FlutterFragmentActivity() {
    private var methodChannel: MethodChannel? = null
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingAction = actionFor(intent)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "consumePendingAction") {
                result.success(pendingAction)
                pendingAction = null
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = actionFor(intent)
        if (action != null) {
            methodChannel?.invokeMethod(action, null)
        }
    }

    private fun actionFor(intent: Intent?): String? {
        return if (intent?.action == ACTION_OPEN_SCANNER) "openCamera" else null
    }

    companion object {
        const val CHANNEL = "com.ahmedmutlag.camscannerall/quick_tile"
        const val ACTION_OPEN_SCANNER = "com.ahmedmutlag.camscannerall.OPEN_SCANNER"
    }
}
