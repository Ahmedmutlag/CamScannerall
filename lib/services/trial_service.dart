import 'database_service.dart';

/// Handles the 7-day free trial logic. Purely local — no server check.
class TrialService {
  TrialService(this._db);

  final DatabaseService _db;

  static const trialDurationDays = 7;

  /// Call once on first app boot to stamp the trial start date.
  Future<void> ensureTrialStarted() async {
    final settings = _db.settings;
    if (settings.trialStartDate == null) {
      settings.trialStartDate = DateTime.now();
      await _db.saveSettings(settings);
    }
  }

  DateTime get trialStart => _db.settings.trialStartDate ?? DateTime.now();

  int get daysLeft {
    final elapsed = DateTime.now().difference(trialStart).inHours / 24;
    final left = trialDurationDays - elapsed;
    if (left <= 0) return 0;
    return left.ceil();
  }

  bool get isTrialActive => daysLeft > 0;

  bool get isPurchased => _db.settings.isPurchased;

  /// True when the app should show the paywall and block all functionality.
  bool get isLocked => !isPurchased && !isTrialActive;
}
