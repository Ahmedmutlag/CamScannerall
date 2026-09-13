import 'package:hive/hive.dart';

/// Singleton-style application settings, stored as a single Hive object.
class AppSettings extends HiveObject {
  AppSettings({
    this.pinHash,
    this.biometricEnabled = false,
    this.autoLockMinutes = 15,
    this.lastBackupDate,
    this.viewMode = 'list',
    this.languageCode = 'ar',
    this.autoBackupFolderPath,
  });

  String? pinHash;
  bool biometricEnabled;
  int autoLockMinutes;
  DateTime? lastBackupDate;
  String viewMode; // 'grid' or 'list'
  String languageCode; // 'ar' or 'en'
  String? autoBackupFolderPath;
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
      viewMode: fields[4] as String? ?? 'list',
      languageCode: fields[5] as String? ?? 'ar',
      autoBackupFolderPath: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.pinHash)
      ..writeByte(1)
      ..write(obj.biometricEnabled)
      ..writeByte(2)
      ..write(obj.autoLockMinutes)
      ..writeByte(3)
      ..write(obj.lastBackupDate)
      ..writeByte(4)
      ..write(obj.viewMode)
      ..writeByte(5)
      ..write(obj.languageCode)
      ..writeByte(6)
      ..write(obj.autoBackupFolderPath);
  }
}
