import 'package:flutter/services.dart';

/// Talks to the native Android Quick Settings Tile bridge (see
/// MainActivity.kt / ScanTileService.kt). The native side stores a
/// "pending action" instead of pushing it immediately, because pushing
/// would race Dart's own startup before any handler is registered.
class QuickTileChannel {
  static const MethodChannel _channel =
      MethodChannel('com.ahmedmutlag.camscannerall/quick_tile');

  static void listen(void Function() onOpenCamera) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openCamera') onOpenCamera();
    });
  }

  /// Call once after the handler above is registered (e.g. on first
  /// frame) to pick up a tile tap that happened while the app was cold.
  static Future<bool> consumePendingAction() async {
    try {
      final action = await _channel.invokeMethod<String>('consumePendingAction');
      return action == 'openCamera';
    } catch (_) {
      return false;
    }
  }
}
