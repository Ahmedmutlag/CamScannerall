import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/doc_page.dart';
import '../models/document.dart';
import '../models/folder.dart';

/// Central access point to the local Hive database. Everything lives
/// on-device — there is no network call anywhere in this class.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _foldersBoxName = 'folders';
  static const _documentsBoxName = 'documents';
  static const _settingsBoxName = 'settings';
  static const _settingsKey = 'app_settings';

  late Box<Folder> foldersBox;
  late Box<Document> documentsBox;
  late Box<AppSettings> settingsBox;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FolderAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DocumentAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DocPageAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AppSettingsAdapter());

    foldersBox = await Hive.openBox<Folder>(_foldersBoxName);
    documentsBox = await Hive.openBox<Document>(_documentsBoxName);
    settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

    if (settingsBox.get(_settingsKey) == null) {
      await settingsBox.put(_settingsKey, AppSettings());
    }

    _initialized = true;
  }

  // ---------------- Settings ----------------

  AppSettings get settings => settingsBox.get(_settingsKey)!;

  Future<void> saveSettings(AppSettings settings) async {
    await settingsBox.put(_settingsKey, settings);
  }

  // ---------------- Folders ----------------

  List<Folder> get allFolders =>
      foldersBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> addFolder(Folder folder) async {
    await foldersBox.put(folder.id, folder);
  }

  Future<void> deleteFolder(String folderId, {bool deleteDocuments = true}) async {
    if (deleteDocuments) {
      final docs = documentsForFolder(folderId).toList();
      for (final doc in docs) {
        await deleteDocument(doc.id);
      }
    }
    await foldersBox.delete(folderId);
  }

  Folder? folderById(String id) => foldersBox.get(id);

  // ---------------- Documents ----------------

  List<Document> get allDocuments => documentsBox.values.toList();

  Iterable<Document> documentsForFolder(String folderId) =>
      documentsBox.values.where((d) => d.folderId == folderId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> addDocument(Document document) async {
    await documentsBox.put(document.id, document);
  }

  Future<void> updateDocument(Document document) async {
    await document.save();
  }

  Future<void> deleteDocument(String documentId) async {
    await documentsBox.delete(documentId);
  }

  Document? documentById(String id) => documentsBox.get(id);

  /// Simple recency-ordered activity feed across all documents.
  List<Document> get recentActivity =>
      documentsBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Search by name or extracted OCR text, across all folders.
  List<Document> search(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    return documentsBox.values
        .where((d) =>
            d.name.toLowerCase().contains(lower) ||
            d.extractedText.toLowerCase().contains(lower))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
