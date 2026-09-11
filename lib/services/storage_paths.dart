import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// All scanned page images live inside the app's private sandbox directory
/// (never the public gallery), so nothing about the user's documents is
/// visible outside the app.
class StoragePaths {
  static Directory? _scansDir;

  static Future<Directory> scansDirectory() async {
    if (_scansDir != null) return _scansDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/scans');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _scansDir = dir;
    return dir;
  }

  static Future<Directory> signaturesDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/signatures');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> tempExportDirectory() async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/export');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
