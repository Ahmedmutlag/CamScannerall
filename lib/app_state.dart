import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
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
import 'services/gallery_service.dart';
import 'services/image_processing_service.dart';
import 'services/ocr_service.dart';
import 'services/pdf_service.dart';
import 'services/share_service.dart';
import 'services/storage_paths.dart';

/// The single composition root: owns every service instance and exposes
/// the cross-cutting operations screens need (folder/document CRUD, the
/// capture -> OCR -> duplicate-check -> save pipeline).
class AppState extends ChangeNotifier {
  final DatabaseService db = DatabaseService.instance;
  final OcrService ocr = OcrService();
  final ImageProcessingService imageProcessing = ImageProcessingService();
  final PdfService pdf = PdfService();
  final DocxExportService docx = DocxExportService();
  late final BackupService backup = BackupService(db);
  late final DuplicateDetectionService duplicates = DuplicateDetectionService(db);
  final ShareService share = ShareService();
  final ExportService export = ExportService();
  final GalleryService gallery = GalleryService();

  static const String defaultFolderId = 'default';

  AppStrings get strings => AppStrings(db.settings.languageCode);

  bool get isRtl => db.settings.languageCode == 'ar';

  Future<void> init() async {
    await db.init();
    await _ensureDefaultFolder();

    final hasAutoBackupFolder = (db.settings.autoBackupFolderPath ?? '').isNotEmpty;
    if (hasAutoBackupFolder) {
      await backup.maybeRunAutomaticBackup();
    }
  }

  /// Whether the in-app backup reminder (bell badge on Home) should show —
  /// only relevant when there's no auto-backup folder configured, since
  /// that path already backs up silently on its own. Replaces a previous
  /// OS notification for the same reminder, which showed a confusing
  /// system badge/permission prompt for something only actionable inside
  /// the app anyway.
  bool get backupReminderDue {
    final hasAutoBackupFolder = (db.settings.autoBackupFolderPath ?? '').isNotEmpty;
    return !hasAutoBackupFolder && backup.autoBackupDue;
  }

  /// Every quick scan/import from the Home screen lands here unless the
  /// user explicitly organizes it into another folder from the Files tab
  /// — keeps the primary flow (open app, scan, done) free of an upfront
  /// "which folder?" prompt.
  Future<void> _ensureDefaultFolder() async {
    if (db.folderById(defaultFolderId) != null) return;
    await db.addFolder(Folder(
      id: defaultFolderId,
      name: strings.t('documents'),
      createdAt: DateTime.now(),
    ));
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
      if (folder.id != defaultFolderId) {
        await db.deleteFolder(folder.id, deleteDocuments: false);
      }
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
    String? folderId,
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

    final extractedText = await _tryExtractText(highResPaths) ?? '';
    final name = nameOverride ?? ocr.suggestName(extractedText, fallback: strings.t('documents'));

    final document = Document(
      id: docId,
      folderId: folderId ?? defaultFolderId,
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

  /// Imports pages already produced elsewhere (an existing image, or a
  /// PDF rasterized page-by-page) as a new document — same save pipeline
  /// as a fresh scan, minus perspective correction (nothing to rectify).
  Future<(Document, Document?)> importPages({
    String? folderId,
    required List<Uint8List> pageBytesList,
    String? nameOverride,
  }) async {
    final outDir = await StoragePaths.scansDirectory();
    final tempDir = await Directory.systemTemp.createTemp('import');
    final pages = <({String highRes, String lowRes})>[];
    for (final bytes in pageBytesList) {
      final pageId = const Uuid().v4();
      final tempFile = File('${tempDir.path}/$pageId.png');
      await tempFile.writeAsBytes(bytes);
      final (highRes, lowRes) = await imageProcessing.processAndSave(
        sourcePath: tempFile.path,
        outputDir: outDir.path,
        pageId: pageId,
      );
      pages.add((highRes: highRes, lowRes: lowRes));
    }
    await tempDir.delete(recursive: true);
    return createDocumentFromPages(folderId: folderId, pages: pages, nameOverride: nameOverride);
  }

  /// Rasterizes an existing PDF file into one page image per PDF page, at
  /// print quality, using the `printing` package (already a dependency
  /// for the app's own PDF export) — no extra dependency needed just to
  /// let the user import a PDF they already have.
  Future<List<Uint8List>> rasterizePdf(Uint8List pdfBytes) async {
    final pages = <Uint8List>[];
    await for (final page in Printing.raster(pdfBytes, dpi: 200)) {
      pages.add(await page.toPng());
    }
    return pages;
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

  /// [newIndex] must already be pre-adjusted for the removed item at
  /// [oldIndex] — i.e. this expects `onReorderItem` semantics, not the
  /// deprecated `onReorder` ones.
  Future<void> reorderPages(Document doc, int oldIndex, int newIndex) async {
    final pages = List<DocPage>.from(doc.pages);
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

  /// Rotates a single saved page 90° clockwise (professional touch-up:
  /// the scanner sometimes gets a page's orientation wrong and there was
  /// previously no way to fix just one page after the fact).
  Future<void> rotatePage(Document doc, DocPage page) async {
    await imageProcessing.rotateSavedPage(
      highResPath: page.imagePathHighRes,
      lowResPath: page.imagePathLowRes,
    );
    notifyListeners();
  }

  /// Trims a single saved page to [rect] (fractions 0..1 of its own
  /// width/height) — a manual fix for when the scanner's automatic crop
  /// left in a margin or part of the surface underneath.
  Future<void> cropPage(Document doc, DocPage page, Rect rect) async {
    await imageProcessing.cropSavedPage(
      highResPath: page.imagePathHighRes,
      lowResPath: page.imagePathLowRes,
      rect: rect,
    );
    notifyListeners();
  }

  /// Duplicates a single page in place, right after the original — for
  /// when a page needs two independent copies to edit differently (e.g.
  /// keep one as-is and crop/rotate the other).
  Future<void> duplicatePage(Document doc, DocPage page) async {
    final newId = const Uuid().v4();
    final newHighRes = page.imagePathHighRes.replaceFirst(RegExp(r'([^/]+)$'), '${newId}_hi.jpg');
    final newLowRes = page.imagePathLowRes.replaceFirst(RegExp(r'([^/]+)$'), '${newId}_lo.jpg');
    await File(page.imagePathHighRes).copy(newHighRes);
    await File(page.imagePathLowRes).copy(newLowRes);

    final pages = List<DocPage>.from(doc.pages)..sort((a, b) => a.order.compareTo(b.order));
    final insertAt = pages.indexOf(page) + 1;
    pages.insert(insertAt, DocPage(
      id: newId,
      documentId: doc.id,
      imagePathHighRes: newHighRes,
      imagePathLowRes: newLowRes,
      order: 0,
    ));
    for (var i = 0; i < pages.length; i++) {
      pages[i].order = i;
    }
    doc.pages = pages;
    await doc.save();
    notifyListeners();
  }

  /// Combines the pages of several existing documents into a single PDF —
  /// a "professional" merge tool distinct from the per-folder ZIP export,
  /// which keeps documents as separate files.
  Future<Uint8List> mergeDocumentsToPdf(List<Document> docs) {
    final paths = docs.expand((d) => d.pages.map((p) => p.imagePathHighRes)).toList();
    return pdf.buildPdf(paths);
  }

  /// Appends freshly captured pages to an existing [doc] (re-running OCR
  /// across the full, now-longer page set) instead of creating a new
  /// document.
  Future<void> addPagesToDocument(
    Document doc,
    List<({String highRes, String lowRes})> pages,
  ) async {
    var order = doc.pages.length;
    final newPages = <DocPage>[];
    for (final p in pages) {
      newPages.add(DocPage(
        id: const Uuid().v4(),
        documentId: doc.id,
        imagePathHighRes: p.highRes,
        imagePathLowRes: p.lowRes,
        order: order,
      ));
      order++;
    }
    doc.pages = [...doc.pages, ...newPages];
    // Keeps the previous extracted text if re-OCR fails, rather than
    // wiping out already-working search text over a transient OCR error.
    final newText = await _tryExtractText(doc.pages.map((p) => p.imagePathHighRes).toList());
    if (newText != null) doc.extractedText = newText;
    await doc.save();
    notifyListeners();
  }

  /// OCR text is a nice-to-have (search, suggested names) rather than a
  /// hard requirement for a scan to save successfully, so a failure here is
  /// logged and swallowed instead of blocking the whole save pipeline.
  Future<String?> _tryExtractText(List<String> imagePaths) async {
    try {
      return await ocr.extractTextFromPages(imagePaths);
    } catch (e) {
      debugPrint('OCR extraction failed: $e');
      return null;
    }
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
