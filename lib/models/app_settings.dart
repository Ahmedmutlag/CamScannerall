import 'package:hive/hive.dart';

/// Singleton-style application settings, stored as a single Hive object.
class AppSettings extends HiveObject {
  AppSettings({
    this.lastBackupDate,
    this.viewMode = 'list',
    this.languageCode = 'ar',
    this.autoBackupFolderPath,
  });

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
      lastBackupDate: fields[3] as DateTime?,
      viewMode: fields[4] as String? ?? 'list',
      languageCode: fields[5] as String? ?? 'ar',
      autoBackupFolderPath: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(4)
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
