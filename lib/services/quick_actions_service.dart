import 'package:quick_actions/quick_actions.dart';

/// Registers the "Scan document" home-screen shortcut. The matching
/// Android Quick Settings Tile is implemented natively (see
/// android/.../ScanTileService.kt) since `quick_actions` only covers
/// launcher shortcuts, not the notification-shade quick-settings tile.
class QuickActionsService {
  static const String scanActionType = 'action_scan';

  final QuickActions _quickActions = const QuickActions();

  Future<void> init({required void Function(String type) onAction}) async {
    _quickActions.initialize(onAction);
    await _quickActions.setShortcutItems(const [
      ShortcutItem(
        type: scanActionType,
        localizedTitle: 'مسح مستند',
        icon: 'ic_scan_shortcut',
      ),
    ]);
  }
}
