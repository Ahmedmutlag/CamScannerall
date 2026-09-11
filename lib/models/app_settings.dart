import 'package:hive/hive.dart';

/// Singleton-style application settings, stored as a single Hive object.
class AppSettings extends HiveObject {
  AppSettings({
    this.pinHash,
    this.biometricEnabled = false,
    this.autoLockMinutes = 15,
    this.lastBackupDate,
    this.trialStartDate,
    this.isPurchased = false,
    this.viewMode = 'grid',
    this.languageCode = 'ar',
  });

  String? pinHash;
  bool biometricEnabled;
  int autoLockMinutes;
  DateTime? lastBackupDate;
  DateTime? trialStartDate;
  bool isPurchased;
  String viewMode; // 'grid' or 'list'
  String languageCode; // 'ar' or 'en'
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      pinHash: fields[0] as String?,
      biometricEnabled: fields[1] as bool? ?? false,
      autoLockMinutes: fields[2] as int? ?? 15,
      lastBackupDate: fields[3] as DateTime?,
      trialStartDate: fields[4] as DateTime?,
      isPurchased: fields[5] as bool? ?? false,
      viewMode: fields[6] as String? ?? 'grid',
      languageCode: fields[7] as String? ?? 'ar',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.pinHash)
      ..writeByte(1)
      ..write(obj.biometricEnabled)
      ..writeByte(2)
      ..write(obj.autoLockMinutes)
      ..writeByte(3)
      ..write(obj.lastBackupDate)
      ..writeByte(4)
      ..write(obj.trialStartDate)
      ..writeByte(5)
      ..write(obj.isPurchased)
      ..writeByte(6)
      ..write(obj.viewMode)
      ..writeByte(7)
      ..write(obj.languageCode);
  }
}
