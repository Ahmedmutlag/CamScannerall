import 'package:hive/hive.dart';

/// A single scanned page that belongs to a [Document].
class DocPage extends HiveObject {
  DocPage({
    required this.id,
    required this.documentId,
    required this.imagePathHighRes,
    required this.imagePathLowRes,
    required this.order,
  });

  String id;
  String documentId;
  String imagePathHighRes;
  String imagePathLowRes;
  int order;
}

class DocPageAdapter extends TypeAdapter<DocPage> {
  @override
  final int typeId = 2;

  @override
  DocPage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocPage(
      id: fields[0] as String,
      documentId: fields[1] as String,
      imagePathHighRes: fields[2] as String,
      imagePathLowRes: fields[3] as String,
      order: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DocPage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.documentId)
      ..writeByte(2)
      ..write(obj.imagePathHighRes)
      ..writeByte(3)
      ..write(obj.imagePathLowRes)
      ..writeByte(4)
      ..write(obj.order);
  }
}
