import 'package:hive/hive.dart';

/// Singleton-style application settings, stored as a single Hive object.
class AppSettings extends HiveObject {
  AppSettings({
    this.viewMode = 'list',
    this.languageCode = 'ar',
  });

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
      viewMode: fields[4] as String? ?? 'list',
      languageCode: fields[5] as String? ?? 'ar',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(2)
      ..writeByte(4)
      ..write(obj.viewMode)
      ..writeByte(5)
      ..write(obj.languageCode);
  }
}
