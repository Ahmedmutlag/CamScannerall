import 'package:hive/hive.dart';
import 'doc_page.dart';

/// A scanned document made of one or more [DocPage]s.
class Document extends HiveObject {
  Document({
    required this.id,
    required this.folderId,
    required this.name,
    required this.pages,
    this.extractedText = '',
    required this.createdAt,
    this.colorTag,
  });

  String id;
  String folderId;
  String name;
  List<DocPage> pages;
  String extractedText;
  DateTime createdAt;
  int? colorTag;
}

class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 1;

  @override
  Document read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Document(
      id: fields[0] as String,
      folderId: fields[1] as String,
      name: fields[2] as String,
      pages: (fields[3] as List).cast<DocPage>(),
      extractedText: fields[4] as String? ?? '',
      createdAt: fields[5] as DateTime,
      colorTag: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.pages)
      ..writeByte(4)
      ..write(obj.extractedText)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.colorTag);
  }
}
