import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/image_processing_service.dart';

class CropAdjustResult {
  CropAdjustResult({required this.corners, required this.filter});
  final List<Offset> corners; // pixel-space corners: TL, TR, BR, BL
  final ScanFilter filter;
}

/// Lets the user fine-tune the auto-detected page edges (as four
/// draggable corner handles) and pick a filter before the page is
/// committed. There's no live native edge-detector in this build, so the
/// initial corners default to a small inset of the full photo, which the
/// user can drag to match the real page edges.
class CropAdjustScreen extends StatefulWidget {
  const CropAdjustScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<CropAdjustScreen> createState() => _CropAdjustScreenState();
}

class _CropAdjustScreenState extends State<CropAdjustScreen> {
  ui.Image? _image;
  ScanFilter _filter = ScanFilter.auto;

  // Corners in normalized (0..1) widget-local space: TL, TR, BR, BL.
  List<Offset> _corners = const [
    Offset(0.06, 0.06),
    Offset(0.94, 0.06),
    Offset(0.94, 0.94),
    Offset(0.06, 0.94),
  ];

  final _imageBoxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  void _dragCorner(int index, DragUpdateDetails details, Size boxSize) {
    final box = _imageBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final normalized = Offset(
      (local.dx / boxSize.width).clamp(0.0, 1.0),
      (local.dy / boxSize.height).clamp(0.0, 1.0),
    );
    setState(() {
      final updated = List<Offset>.from(_corners);
      updated[index] = normalized;
      _corners = updated;
    });
  }

  void _confirm() {
    if (_image == null) return;
    final pixelCorners = _corners
        .map((c) => Offset(c.dx * _image!.width, c.dy * _image!.height))
        .toList();
    Navigator.of(context).pop(CropAdjustResult(corners: pixelCorners, filter: _filter));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;

    if (_image == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final aspect = _image!.width / _image!.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(s.t('documentDetails')),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxSize = Size(constraints.maxWidth, constraints.maxHeight);
                    return Stack(
                      key: _imageBoxKey,
                      children: [
                        Positioned.fill(
                          child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
                        ),
                        CustomPaint(
                          size: boxSize,
                          painter: _QuadPainter(_corners),
                        ),
                        for (var i = 0; i < _corners.length; i++)
                          Positioned(
                            left: _corners[i].dx * boxSize.width - 16,
                            top: _corners[i].dy * boxSize.height - 16,
                            child: GestureDetector(
                              onPanUpdate: (d) => _dragCorner(i, d, boxSize),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue, width: 3),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  _filterChip(ScanFilter.auto, s.t('filterAuto')),
                  _filterChip(ScanFilter.blackAndWhite, s.t('filterBW')),
                  _filterChip(ScanFilter.color, s.t('filterColor')),
                  _filterChip(ScanFilter.original, s.t('filterOriginal')),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.t('retake')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _confirm, child: Text(s.t('done'))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.corners);
  final List<Offset> corners;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..moveTo(corners[0].dx * size.width, corners[0].dy * size.height);
    for (final c in corners.skip(1)) {
      path.lineTo(c.dx * size.width, c.dy * size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) => oldDelegate.corners != corners;
}
