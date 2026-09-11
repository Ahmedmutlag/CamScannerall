import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Generic file sharing (any installed app: WhatsApp, email, Telegram...)
/// for artifacts that are not plain PDFs (images, .docx, text index...).
/// PDF sharing/printing goes through [PdfService], which uses `printing`
/// for a richer share sheet that also supports direct printing.
class ShareService {
  Future<void> shareBytes(Uint8List bytes, String filename, {String? mimeType, String? text}) async {
    final tempDir = await Directory.systemTemp.createTemp('share');
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)], text: text);
  }

  Future<void> shareFiles(List<String> paths, {String? text}) async {
    await Share.shareXFiles(paths.map((p) => XFile(p)).toList(), text: text);
  }
}
