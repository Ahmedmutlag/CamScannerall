import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../services/image_processing_service.dart';
import '../services/storage_paths.dart';
import 'crop_adjust_screen.dart';

class _PendingPage {
  _PendingPage({required this.rawPath, required this.corners, required this.filter});
  final String rawPath;
  final List<Offset> corners;
  final ScanFilter filter;
}

/// The scan/capture screen: live preview, edge-adjust + filter per page,
/// multi-page capture in one session, gallery import, and a 3-second
/// self-timer to reduce shake.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.quickMode = false});

  /// When true, the caller only wants the processed page paths back
  /// (used by "quick scan & share" and by the add-document flow, which
  /// both push this screen and read the popped result themselves).
  final bool quickMode;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _initializing = true;
  String? _permissionError;
  bool _timerEnabled = false;
  bool _capturing = false;
  int _countdown = 0;

  final List<_PendingPage> _pending = [];

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _permissionError = 'camera_denied';
        _initializing = false;
      });
      return;
    }
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.veryHigh, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      setState(() {
        _permissionError = 'camera_error';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;

    if (_timerEnabled) {
      for (var i = 3; i >= 1; i--) {
        if (!mounted) return;
        setState(() => _countdown = i);
        await Future.delayed(const Duration(seconds: 1));
      }
      setState(() => _countdown = 0);
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      await _reviewCapturedImage(file.path);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _importFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (file == null) return;
    await _reviewCapturedImage(file.path);
  }

  Future<void> _reviewCapturedImage(String path) async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<CropAdjustResult>(
      MaterialPageRoute(builder: (_) => CropAdjustScreen(imagePath: path)),
    );
    if (result == null) return;
    setState(() {
      _pending.add(_PendingPage(rawPath: path, corners: result.corners, filter: result.filter));
    });
    if (_pending.length == 1) {
      await _maybeSuggestBackSide(path);
    }
  }

  /// Heuristic: a single freshly captured page whose aspect ratio is close
  /// to a standard ID/credit card (~1.586:1) probably means the user is
  /// scanning a card — offer to scan the back side too.
  Future<void> _maybeSuggestBackSide(String path) async {
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
    // Either way the capture flow already supports adding more pages; this
    // is just a nudge, so no further action is required here.
    if (wantsBack == true && mounted) {
      // No-op: the camera preview is already visible for the next capture.
    }
  }

  Future<void> _finishSession() async {
    if (_pending.isEmpty) {
      Navigator.of(context).pop(<({String highRes, String lowRes})>[]);
      return;
    }
    final appState = context.read<AppState>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final outputs = <({String highRes, String lowRes})>[];
    final outDir = await StoragePaths.scansDirectory();
    for (final page in _pending) {
      final pageId = const Uuid().v4();
      final (hi, lo) = await appState.imageProcessing.processAndSave(
        sourcePath: page.rawPath,
        outputDir: outDir.path,
        pageId: pageId,
        corners: page.corners,
        filter: page.filter,
      );
      outputs.add((highRes: hi, lowRes: lo));
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // close progress dialog
    Navigator.of(context).pop(outputs);
  }

  void _removePending(int index) {
    setState(() => _pending.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;

    if (_initializing) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    if (_permissionError != null || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('camera'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _permissionError == 'camera_denied'
                  ? 'يحتاج التطبيق إذن الكاميرا لمسح المستندات.'
                  : 'تعذر تشغيل الكاميرا على هذا الجهاز.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller!),
                  if (_countdown > 0)
                    Center(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(<({String highRes, String lowRes})>[]),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.timer,
                        color: _timerEnabled ? Colors.amber : Colors.white,
                      ),
                      onPressed: () => setState(() => _timerEnabled = !_timerEnabled),
                    ),
                  ),
                ],
              ),
            ),
            if (_pending.isNotEmpty)
              SizedBox(
                height: 76,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: _pending.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_pending[index].rawPath), width: 52, height: 60, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            iconSize: 18,
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => _removePending(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 30),
                    onPressed: _importFromGallery,
                  ),
                  GestureDetector(
                    onTap: _capturing ? null : _capture,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: _capturing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  TextButton(
                    onPressed: _finishSession,
                    child: Text(
                      '${s.t('done')} (${_pending.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
