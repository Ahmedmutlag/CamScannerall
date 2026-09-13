import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/doc_page.dart';
import '../models/document.dart';
import '../models/folder.dart';
import 'crypto_helper.dart';
import 'database_service.dart';
import 'storage_paths.dart';

/// Fully local, password-encrypted backup & restore. There is no account,
/// no email, no IP-based identification: the only key to the data is the
/// password the user chooses at export time, and the only artifact is a
/// single encrypted file the user stores wherever they like.
///
/// A second, silent path exists for the periodic automatic backup (see
/// [maybeRunAutomaticBackup]): since nothing can prompt for a password
/// every 60 days unattended, those backups are encrypted with a random key
/// generated once and held in secure storage. That key never leaves the
/// device, so an automatic backup file is only ever restorable on the same
/// device/install — it is not a substitute for the portable, user-password
/// backup above if the device itself is lost.
class BackupService {
  BackupService(this._db);

  final DatabaseService _db;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _autoBackupKeyStorageKey = 'auto_backup_key';
  static const autoBackupFileName = 'camscanner_auto_backup.dsbackup';
  static const Duration autoBackupInterval = Duration(days: 60);

  Future<String?> _readAutoBackupKey() => _secureStorage.read(key: _autoBackupKeyStorageKey);

  Future<String> _getOrCreateAutoBackupKey() async {
    var key = await _readAutoBackupKey();
    if (key == null) {
      key = base64UrlEncode(CryptoHelper.randomBytes(32));
      await _secureStorage.write(key: _autoBackupKeyStorageKey, value: key);
    }
    return key;
  }

  Future<void> setAutoBackupFolder(String? path) async {
    final settings = _db.settings;
    settings.autoBackupFolderPath = path;
    await _db.saveSettings(settings);
  }

  bool get autoBackupDue {
    final last = _db.settings.lastBackupDate;
    return last == null || DateTime.now().difference(last) >= autoBackupInterval;
  }

  /// Silently writes an internally-encrypted backup into the configured
  /// folder if one is set and a backup is due. Returns true if a backup
  /// was actually written.
  Future<bool> maybeRunAutomaticBackup() async {
    final folderPath = _db.settings.autoBackupFolderPath;
    if (folderPath == null || folderPath.isEmpty || !autoBackupDue) return false;

    final key = await _getOrCreateAutoBackupKey();
    final bytes = await createBackup(key);
    final file = File('$folderPath/$autoBackupFileName');
    await file.writeAsBytes(bytes, flush: true);
    await markBackupDone();
    return true;
  }

  /// Restores from the automatic backup file in the configured folder,
  /// using the device-held internal key. Fails (returns
  /// [BackupRestoreResult.wrongPasswordOrCorrupted]) if no internal key or
  /// no backup file exists yet, or if the key doesn't match the file (e.g.
  /// after reinstalling the app, which clears secure storage).
  Future<BackupRestoreResult> restoreFromAutoBackupFolder() async {
    final folderPath = _db.settings.autoBackupFolderPath;
    final key = await _readAutoBackupKey();
    if (folderPath == null || folderPath.isEmpty || key == null) {
      return BackupRestoreResult.wrongPasswordOrCorrupted;
    }
    final file = File('$folderPath/$autoBackupFileName');
    if (!await file.exists()) return BackupRestoreResult.wrongPasswordOrCorrupted;
    return restoreBackup(await file.readAsBytes(), key);
  }

  /// Builds the encrypted backup file bytes for the given [password].
  Future<Uint8List> createBackup(String password) async {
    final scansDir = await StoragePaths.scansDirectory();

    final manifest = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': _db.allFolders
          .map((f) => {
                'id': f.id,
                'name': f.name,
                'colorTag': f.colorTag,
                'createdAt': f.createdAt.toIso8601String(),
              })
          .toList(),
      'documents': _db.allDocuments
          .map((d) => {
                'id': d.id,
                'folderId': d.folderId,
                'name': d.name,
                'extractedText': d.extractedText,
                'createdAt': d.createdAt.toIso8601String(),
                'colorTag': d.colorTag,
                'manualValidUntilNote': d.manualValidUntilNote,
                'locationNote': d.locationNote,
                'pages': d.pages
                    .map((p) => {
                          'id': p.id,
                          'order': p.order,
                          'hi': 'images/${p.id}_hi.jpg',
                          'lo': 'images/${p.id}_lo.jpg',
                        })
                    .toList(),
              })
          .toList(),
    };

    final archive = Archive();
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    for (final doc in _db.allDocuments) {
      for (final page in doc.pages) {
        await _addFileIfExists(archive, '${scansDir.path}/${page.id}_hi.jpg', 'images/${page.id}_hi.jpg');
        await _addFileIfExists(archive, '${scansDir.path}/${page.id}_lo.jpg', 'images/${page.id}_lo.jpg');
      }
    }

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    return compute(_encryptPayload, {'password': password, 'data': zipBytes});
  }

  Future<void> _addFileIfExists(Archive archive, String path, String archivePath) async {
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(archivePath, bytes.length, bytes));
    }
  }

  /// Result of a restore attempt.
  Future<BackupRestoreResult> restoreBackup(Uint8List backupBytes, String password) async {
    Uint8List zipBytes;
    try {
      zipBytes = await compute(_decryptPayload, {'password': password, 'data': backupBytes});
    } catch (_) {
      return BackupRestoreResult.wrongPasswordOrCorrupted;
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      return BackupRestoreResult.wrongPasswordOrCorrupted;
    }

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) return BackupRestoreResult.wrongPasswordOrCorrupted;

    final Map<String, dynamic> manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>;

    final scansDir = await StoragePaths.scansDirectory();

    // Replace local data: restoring is meant for the "lost/reinstalled
    // device" scenario, so we start from a clean slate.
    for (final doc in _db.allDocuments) {
      await _db.deleteDocument(doc.id);
    }
    for (final folder in _db.allFolders) {
      await _db.foldersBox.delete(folder.id);
    }

    for (final f in (manifest['folders'] as List)) {
      final map = f as Map<String, dynamic>;
      await _db.addFolder(Folder(
        id: map['id'] as String,
        name: map['name'] as String,
        colorTag: map['colorTag'] as int?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      ));
    }

    for (final d in (manifest['documents'] as List)) {
      final map = d as Map<String, dynamic>;
      final pages = <DocPage>[];
      for (final p in (map['pages'] as List)) {
        final pMap = p as Map<String, dynamic>;
        final pageId = pMap['id'] as String? ?? const Uuid().v4();
        final hiEntry = archive.findFile(pMap['hi'] as String);
        final loEntry = archive.findFile(pMap['lo'] as String);
        final hiPath = '${scansDir.path}/${pageId}_hi.jpg';
        final loPath = '${scansDir.path}/${pageId}_lo.jpg';
        if (hiEntry != null) {
          await File(hiPath).writeAsBytes(hiEntry.content as List<int>);
        }
        if (loEntry != null) {
          await File(loPath).writeAsBytes(loEntry.content as List<int>);
        }
        pages.add(DocPage(
          id: pageId,
          documentId: map['id'] as String,
          imagePathHighRes: hiPath,
          imagePathLowRes: loPath,
          order: pMap['order'] as int? ?? 0,
        ));
      }
      await _db.addDocument(Document(
        id: map['id'] as String,
        folderId: map['folderId'] as String,
        name: map['name'] as String,
        pages: pages,
        extractedText: map['extractedText'] as String? ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        colorTag: map['colorTag'] as int?,
        manualValidUntilNote: map['manualValidUntilNote'] as String?,
        locationNote: map['locationNote'] as String?,
      ));
    }

    final settings = _db.settings;
    settings.lastBackupDate = DateTime.now();
    await _db.saveSettings(settings);

    return BackupRestoreResult.success;
  }

  Future<void> markBackupDone() async {
    final settings = _db.settings;
    settings.lastBackupDate = DateTime.now();
    await _db.saveSettings(settings);
  }
}

enum BackupRestoreResult { success, wrongPasswordOrCorrupted }

const List<int> _magic = [0x44, 0x53, 0x42, 0x31]; // "DSB1"

Uint8List _encryptPayload(Map<String, dynamic> params) {
  final password = params['password'] as String;
  final data = params['data'] as Uint8List;

  final salt = CryptoHelper.randomBytes(CryptoHelper.saltLength);
  final iv = CryptoHelper.randomBytes(CryptoHelper.ivLength);
  final key = CryptoHelper.deriveKey(password, salt);
  final ciphertext = CryptoHelper.encryptAesCbc(key: key, iv: iv, plaintext: data);
  final macKey = Uint8List.fromList(crypto.sha256.convert([...key, ..."MAC".codeUnits]).bytes);
  final mac = CryptoHelper.hmac(macKey, ciphertext);

  return Uint8List.fromList([
    ..._magic,
    ...salt,
    ...iv,
    ...mac,
    ...ciphertext,
  ]);
}

Uint8List _decryptPayload(Map<String, dynamic> params) {
  final password = params['password'] as String;
  final data = params['data'] as Uint8List;

  if (data.length < 4 + CryptoHelper.saltLength + CryptoHelper.ivLength + 32) {
    throw const FormatException('Backup file too short');
  }
  var offset = 0;
  final magic = data.sublist(offset, offset + 4);
  offset += 4;
  if (!_listEquals(magic, _magic)) {
    throw const FormatException('Bad magic header');
  }
  final salt = data.sublist(offset, offset + CryptoHelper.saltLength);
  offset += CryptoHelper.saltLength;
  final iv = data.sublist(offset, offset + CryptoHelper.ivLength);
  offset += CryptoHelper.ivLength;
  final mac = data.sublist(offset, offset + 32);
  offset += 32;
  final ciphertext = data.sublist(offset);

  final key = CryptoHelper.deriveKey(password, Uint8List.fromList(salt));
  final macKey = Uint8List.fromList(crypto.sha256.convert([...key, ..."MAC".codeUnits]).bytes);
  final expectedMac = CryptoHelper.hmac(macKey, Uint8List.fromList(ciphertext));

  if (!_listEquals(expectedMac, mac)) {
    throw const FormatException('Wrong password or corrupted file');
  }

  return CryptoHelper.decryptAesCbc(
    key: key,
    iv: Uint8List.fromList(iv),
    ciphertext: Uint8List.fromList(ciphertext),
  );
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
