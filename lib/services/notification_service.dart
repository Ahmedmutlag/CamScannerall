import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'database_service.dart';

/// Purely local notifications (no push, no server) — used only for the
/// periodic "please back up your data" reminder.
class NotificationService {
  NotificationService(this._db);

  final DatabaseService _db;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _backupReminderId = 9001;
  static const Duration backupReminderInterval = Duration(days: 60);

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
  }

  Future<void> maybeShowBackupReminder(String title, String body) async {
    final last = _db.settings.lastBackupDate;
    final due = last == null || DateTime.now().difference(last) >= backupReminderInterval;
    if (!due) return;

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      if (!result.isGranted) return;
    }

    const androidDetails = AndroidNotificationDetails(
      'backup_reminder',
      'Backup reminders',
      channelDescription: 'Periodic reminder to back up your documents',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _plugin.show(
      _backupReminderId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
