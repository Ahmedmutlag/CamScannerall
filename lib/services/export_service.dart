import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import '../models/document.dart';

/// Batch export helpers: a plain-text index of document names, and a
/// zip bundle combining several already-rendered files (mixed formats)
/// into a single share/save action.
class ExportService {
  Uint8List buildTextIndex(String folderName, List<Document> documents) {
    final buffer = StringBuffer();
    buffer.writeln('فهرس المجلد: $folderName');
    buffer.writeln('تاريخ التصدير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('عدد المستندات: ${documents.length}');
    buffer.writeln('---');
    for (final doc in documents) {
      buffer.writeln('- ${doc.name} (${DateFormat('yyyy-MM-dd').format(doc.createdAt)})');
    }
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Bundles [filesByName] (filename -> bytes) into a single zip archive,
  /// used for batch-exporting several documents of mixed formats at once.
  Uint8List buildZip(Map<String, Uint8List> filesByName) {
    final archive = Archive();
    filesByName.forEach((name, bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }
}
