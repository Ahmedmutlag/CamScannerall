import 'package:hive/hive.dart';

/// A user-named folder. Folders are completely free-form — there are no
/// pre-defined categories per the product spec.
class Folder extends HiveObject {
  Folder({
    required this.id,
    required this.name,
    this.colorTag,
    required this.createdAt,
  });

  String id;
  String name;
  int? colorTag; // ARGB color value, optional
  DateTime createdAt;
}

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final int typeId = 0;

  @override
  Folder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Folder(
      id: fields[0] as String,
      name: fields[1] as String,
      colorTag: fields[2] as int?,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorTag)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}
