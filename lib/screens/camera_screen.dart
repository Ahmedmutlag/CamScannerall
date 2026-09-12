import 'dart:io';
import 'dart:ui' as ui;

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../services/image_processing_service.dart';
import '../services/storage_paths.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_view.dart';

/// The scan/capture screen. Capture itself is delegated to
/// `cunning_document_scanner`, which drives Google's ML Kit document
/// scanner on Android and Apple's VisionKit document camera on iOS — both
/// give a real live automatic edge/corner detector during capture (with a
/// manual crop-rectangle fallback on Android devices without Play
/// Services), instead of a hand-rolled one. This screen then lets the user
/// pick a filter and review the pages before they're saved.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.quickMode = false});

  /// When true, the caller only wants the processed page paths back
  /// (used by "quick scan & share" and by the add-document flow, which
  /// both push this screen and read the popped result themselves).
  final bool quickMode;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _ScreenState { scanning, reviewing, error }

class _CameraScreenState extends State<CameraScreen> {
  _ScreenState _state = _ScreenState.scanning;
  String? _errorMessage;
  final List<String> _scannedPaths = [];
  ScanFilter _filter = ScanFilter.auto;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  Future<void> _startScan({int? limitPages}) async {
    setState(() => _state = _ScreenState.scanning);
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: limitPages ?? 100,
        scannerSource: ScannerSource.cameraAndGallery,
        androidScannerMode: AndroidScannerMode.full,
      );
      if (!mounted) return;

      if (pictures == null || pictures.isEmpty) {
        if (_scannedPaths.isEmpty) {
          Navigator.of(context).pop(<({String highRes, String lowRes})>[]);
        } else {
          setState(() => _state = _ScreenState.reviewing);
        }
        return;
      }

      final wasEmpty = _scannedPaths.isEmpty;
      setState(() {
        _scannedPaths.addAll(pictures);
        _state = _ScreenState.reviewing;
      });

      if (wasEmpty && _scannedPaths.length == 1) {
        await _maybeSuggestBackSide();
      }
    } on CunningDocumentScannerException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = e.code == 'permission_denied'
            ? 'يحتاج التطبيق إذن الكاميرا لمسح المستندات — فعّله من إعدادات الجهاز ثم أعد المحاولة.'
            : 'تعذر تشغيل الماسح الضوئي على هذا الجهاز — أعد المحاولة، وإن تكرر الخطأ جرّب إعادة تشغيل الجهاز.';
      });
    }
  }

  /// Heuristic: a single freshly scanned page whose aspect ratio is close
  /// to a standard ID/credit card (~1.586:1) probably means the user is
  /// scanning a card — offer to scan the back side right away.
  Future<void> _maybeSuggestBackSide() async {
    final path = _scannedPaths.first;
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();
      final ratio = w > h ? w / h : h / w;
      if (ratio < 1.35 || ratio > 1.85) return;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final appState = context.read<AppState>();
    final s = appState.strings;
    final wantsBack = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('importFace2')),
        content: Text(s.t('importFace2Body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('no'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('yes'))),
        ],
      ),
    );
    if (wantsBack == true && mounted) {
      await _startScan(limitPages: 1);
    }
  }

  void _removePage(int index) {
    setState(() => _scannedPaths.removeAt(index));
  }

  Future<void> _finish() async {
    if (_scannedPaths.isEmpty) {
      Navigator.of(context).pop(<({String highRes, String lowRes})>[]);
      return;
    }
    setState(() => _processing = true);
    final appState = context.read<AppState>();
    final outputs = <({String highRes, String lowRes})>[];
    final outDir = await StoragePaths.scansDirectory();
    for (final path in _scannedPaths) {
      final pageId = const Uuid().v4();
      // The scanner already cropped/perspective-corrected the page, so no
      // corner data is passed here — only the chosen filter is applied.
      final (hi, lo) = await appState.imageProcessing.processAndSave(
        sourcePath: path,
        outputDir: outDir.path,
        pageId: pageId,
        filter: _filter,
      );
      outputs.add((highRes: hi, lowRes: lo));
    }
    await CunningDocumentScanner.cleanCache();

    if (!mounted) return;
    Navigator.of(context).pop(outputs);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;

    switch (_state) {
      case _ScreenState.scanning:
        return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
      case _ScreenState.error:
        return Scaffold(
          appBar: AppBar(title: Text(s.t('camera'))),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.of(context).error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.of(context).textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: () => _startScan(), child: Text(s.t('retake'))),
                ],
              ),
            ),
          ),
        );
      case _ScreenState.reviewing:
        return Scaffold(
          appBar: AppBar(
            title: Text('${s.t('documentDetails')} (${_scannedPaths.length})'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(<({String highRes, String lowRes})>[]),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _scannedPaths.isEmpty
                    ? EmptyStateView(message: s.t('noDocuments'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: _scannedPaths.length,
                        itemBuilder: (context, index) => Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(_scannedPaths[index]), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => _removePage(index),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.md),
                      _filterChip(ScanFilter.auto, s.t('filterAuto')),
                      _filterChip(ScanFilter.blackAndWhite, s.t('filterBW')),
                      _filterChip(ScanFilter.color, s.t('filterColor')),
                      _filterChip(ScanFilter.original, s.t('filterOriginal')),
                      const SizedBox(width: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : () => _startScan(),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(s.t('addAnotherPage')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _processing ? null : _finish,
                        child: _processing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(s.t('done')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _filterChip(ScanFilter filter, String label) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = filter),
      ),
    );
  }
}
