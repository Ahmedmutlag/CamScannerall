import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'l10n/strings.dart';
import 'models/app_settings.dart';
import 'models/doc_page.dart';
import 'models/document.dart';
import 'models/folder.dart';
import 'services/backup_service.dart';
import 'services/database_service.dart';
import 'services/docx_export_service.dart';
import 'services/duplicate_detection_service.dart';
import 'services/export_service.dart';
import 'services/image_processing_service.dart';
import 'services/lock_service.dart';
import 'services/notification_service.dart';
import 'services/ocr_service.dart';
import 'services/pdf_protection_service.dart';
import 'services/pdf_service.dart';
import 'services/purchase_service.dart';
import 'services/quick_actions_service.dart';
import 'services/share_service.dart';
import 'services/signature_service.dart';
import 'services/trial_service.dart';

/// The single composition root: owns every service instance and exposes
/// the cross-cutting operations screens need (folder/document CRUD, the
/// capture -> OCR -> duplicate-check -> save pipeline, lock state).
/// Individual feature services remain directly accessible for
/// feature-specific screens (backup, signature, PDF tools...).
class AppState extends ChangeNotifier {
  final DatabaseService db = DatabaseService.instance;
  late final TrialService trial = TrialService(db);
  late final LockService lock = LockService(db);
  final OcrService ocr = OcrService();
  final ImageProcessingService imageProcessing = ImageProcessingService();
  final PdfService pdf = PdfService();
  final DocxExportService docx = DocxExportService();
  late final BackupService backup = BackupService(db);
  final SignatureService signature = SignatureService();
  late final NotificationService notifications = NotificationService(db);
  late final DuplicateDetectionService duplicates = DuplicateDetectionService(db);
  final ShareService share = ShareService();
  final ExportService export = ExportService();
  final PdfProtectionService pdfProtection = PdfProtectionService();
  late final PurchaseService purchase = PurchaseService(db);
  final QuickActionsService quickActions = QuickActionsService();

  bool isUnlockedThisSession = false;

  AppStrings get strings => AppStrings(db.settings.languageCode);

  bool get isRtl => db.settings.languageCode == 'ar';

  Future<void> init() async {
    await db.init();
    await trial.ensureTrialStarted();
    await notifications.init();
    await notifications.maybeShowBackupReminder(
      strings.t('backup'),
      strings.t('backupReminderBody'),
    );
    // Store connectivity is not required for the app to function; init in
    // the background so a slow/offline store never blocks app startup.
    // ignore: discarded_futures
    purchase.init();
  }

  // ---------------- Settings ----------------

  Future<void> setLanguage(String code) async {
    final s = db.settings;
    s.languageCode = code;
    await db.saveSettings(s);
    notifyListeners();
  }

  Future<void> setViewMode(String mode) async {
    final s = db.settings;
    s.viewMode = mode;
    await db.saveSettings(s);
    notifyListeners();
  }

  AppSettings get settings => db.settings;

  /// Call after a purchase/restore completes so widgets watching [AppState]
  /// (e.g. the paywall) re-check `trial.isPurchased` and rebuild.
  void refreshPurchaseState() => notifyListeners();

  // ---------------- Folders ----------------

  Future<Folder> createFolder(String name, {int? colorTag}) async {
    final folder = Folder(
      id: const Uuid().v4(),
      name: name,
      colorTag: colorTag,
      createdAt: DateTime.now(),
    );
    await db.addFolder(folder);
    notifyListeners();
    return folder;
  }

  Future<void> renameFolder(Folder folder, String newName) async {
    folder.name = newName;
    await folder.save();
    notifyListeners();
  }

  Future<void> deleteFolder(Folder folder) async {
    await db.deleteFolder(folder.id);
    notifyListeners();
  }

  Future<Folder> mergeFolders(List<Folder> folders, String newName) async {
    final target = await createFolder(newName);
    for (final folder in folders) {
      for (final doc in db.documentsForFolder(folder.id).toList()) {
        doc.folderId = target.id;
        await doc.save();
      }
      await db.deleteFolder(folder.id, deleteDocuments: false);
    }
    notifyListeners();
    return target;
  }

  // ---------------- Documents ----------------

  /// Full pipeline for turning freshly captured/processed page images into
  /// a saved [Document]: runs OCR across all pages, derives a suggested
  /// name, checks for a likely duplicate in the same folder, and persists
  /// everything. Returns the created document plus an optional duplicate
  /// match the caller can warn the user about.
  Future<(Document, Document?)> createDocumentFromPages({
    required String folderId,
    required List<({String highRes, String lowRes})> pages,
    String? nameOverride,
  }) async {
    final docId = const Uuid().v4();
    final docPages = <DocPage>[];
    final highResPaths = <String>[];
    for (var i = 0; i < pages.length; i++) {
      final pageId = const Uuid().v4();
      docPages.add(DocPage(
        id: pageId,
        documentId: docId,
        imagePathHighRes: pages[i].highRes,
        imagePathLowRes: pages[i].lowRes,
        order: i,
      ));
      highResPaths.add(pages[i].highRes);
    }

    final extractedText = await ocr.extractTextFromPages(highResPaths);
    final name = nameOverride ?? ocr.suggestName(extractedText, fallback: strings.t('documents'));

    final document = Document(
      id: docId,
      folderId: folderId,
      name: name,
      pages: docPages,
      extractedText: extractedText,
      createdAt: DateTime.now(),
    );

    final duplicate = duplicates.findLikelyDuplicate(document);

    await db.addDocument(document);
    notifyListeners();
    return (document, duplicate);
  }

  Future<void> renameDocument(Document doc, String newName) async {
    doc.name = newName;
    await doc.save();
    notifyListeners();
  }

  Future<void> deleteDocument(Document doc) async {
    await db.deleteDocument(doc.id);
    notifyListeners();
  }

  Future<void> copyDocumentToFolder(Document doc, String targetFolderId) async {
    final newPages = doc.pages
        .map((p) => DocPage(
              id: const Uuid().v4(),
              documentId: '',
              imagePathHighRes: p.imagePathHighRes,
              imagePathLowRes: p.imagePathLowRes,
              order: p.order,
            ))
        .toList();
    final newDoc = Document(
      id: const Uuid().v4(),
      folderId: targetFolderId,
      name: doc.name,
      pages: newPages,
      extractedText: doc.extractedText,
      createdAt: DateTime.now(),
      colorTag: doc.colorTag,
      manualValidUntilNote: doc.manualValidUntilNote,
      locationNote: doc.locationNote,
    );
    for (final p in newPages) {
      p.documentId = newDoc.id;
    }
    await db.addDocument(newDoc);
    notifyListeners();
  }

  Future<void> moveDocumentToFolder(Document doc, String targetFolderId) async {
    doc.folderId = targetFolderId;
    await doc.save();
    notifyListeners();
  }

  Future<void> reorderPages(Document doc, int oldIndex, int newIndex) async {
    final pages = List<DocPage>.from(doc.pages);
    if (newIndex > oldIndex) newIndex -= 1;
    final page = pages.removeAt(oldIndex);
    pages.insert(newIndex, page);
    for (var i = 0; i < pages.length; i++) {
      pages[i].order = i;
    }
    doc.pages = pages;
    await doc.save();
    notifyListeners();
  }

  Future<void> deletePage(Document doc, DocPage page) async {
    final pages = List<DocPage>.from(doc.pages)..remove(page);
    for (var i = 0; i < pages.length; i++) {
      pages[i].order = i;
    }
    doc.pages = pages;
    await doc.save();
    notifyListeners();
  }

  Future<Document> splitDocument(Document doc, int splitAtIndex) async {
    final sorted = List<DocPage>.from(doc.pages)..sort((a, b) => a.order.compareTo(b.order));
    final firstHalf = sorted.sublist(0, splitAtIndex);
    final secondHalf = sorted.sublist(splitAtIndex);

    doc.pages = firstHalf;
    await doc.save();

    final newDocId = const Uuid().v4();
    final newPages = <DocPage>[];
    for (var i = 0; i < secondHalf.length; i++) {
      final old = secondHalf[i];
      newPages.add(DocPage(
        id: old.id,
        documentId: newDocId,
        imagePathHighRes: old.imagePathHighRes,
        imagePathLowRes: old.imagePathLowRes,
        order: i,
      ));
    }
    final newDoc = Document(
      id: newDocId,
      folderId: doc.folderId,
      name: '${doc.name} (2)',
      pages: newPages,
      extractedText: doc.extractedText,
      createdAt: DateTime.now(),
    );
    await db.addDocument(newDoc);
    notifyListeners();
    return newDoc;
  }
}
