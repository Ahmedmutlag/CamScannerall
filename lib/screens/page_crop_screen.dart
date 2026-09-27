import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/doc_page.dart';
import '../models/document.dart';
import '../theme/app_colors.dart';

/// Manual crop touch-up for a single already-scanned page — for when the
/// scanner's own automatic crop left in a margin or a bit of the surface
/// underneath, and there was previously no way to fix it after capture.
class PageCropScreen extends StatefulWidget {
  const PageCropScreen({super.key, required this.document, required this.page});

  final Document document;
  final DocPage page;

  @override
  State<PageCropScreen> createState() => _PageCropScreenState();
}

class _PageCropScreenState extends State<PageCropScreen> {
  Rect _rect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
  bool _saving = false;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.page.imagePathHighRes).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    await appState.cropPage(widget.document, widget.page, _rect);
    if (mounted) Navigator.of(context).pop();
  }

  void _updateRect(Rect newRect) {
    setState(() {
      _rect = Rect.fromLTRB(
        newRect.left.clamp(0.0, newRect.right - 0.05),
        newRect.top.clamp(0.0, newRect.bottom - 0.05),
        newRect.right.clamp(newRect.left + 0.05, 1.0),
        newRect.bottom.clamp(newRect.top + 0.05, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(s.t('cropPage')),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: AspectRatio(
                aspectRatio: _image!.width / _image!.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(widget.page.imagePathHighRes), fit: BoxFit.fill),
                        _CropOverlay(
                          rect: _rect,
                          size: size,
                          accentColor: colors.accentBrass,
                          onChanged: _updateRect,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// Draws the dimmed-outside/clear-inside crop mask and exposes the 4 corner
/// handles as separate drag targets so resizing feels natural — dragging a
/// corner only ever moves that corner, never rotates or skews the box.
class _CropOverlay extends StatelessWidget {
  const _CropOverlay({
    required this.rect,
    required this.size,
    required this.accentColor,
    required this.onChanged,
  });

  final Rect rect; // fractional (0..1)
  final Size size; // rendered pixel size of the image
  final Color accentColor;
  final ValueChanged<Rect> onChanged;

  Rect get _pixelRect => Rect.fromLTRB(
        rect.left * size.width,
        rect.top * size.height,
        rect.right * size.width,
        rect.bottom * size.height,
      );

  void _dragCorner(DragUpdateDetails details, {required bool isLeft, required bool isTop}) {
    final dx = details.delta.dx / size.width;
    final dy = details.delta.dy / size.height;
    final newRect = Rect.fromLTRB(
      isLeft ? rect.left + dx : rect.left,
      isTop ? rect.top + dy : rect.top,
      !isLeft ? rect.right + dx : rect.right,
      !isTop ? rect.bottom + dy : rect.bottom,
    );
    onChanged(newRect);
  }

  Widget _handle({required bool isLeft, required bool isTop}) {
    final pr = _pixelRect;
    return Positioned(
      left: (isLeft ? pr.left : pr.right) - 14,
      top: (isTop ? pr.top : pr.bottom) - 14,
      child: GestureDetector(
        onPanUpdate: (d) => _dragCorner(d, isLeft: isLeft, isTop: isTop),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pr = _pixelRect;
    return Stack(
      children: [
        // Dim everything outside the crop rect using 4 shaded bars.
        Positioned(left: 0, top: 0, right: 0, height: pr.top, child: const ColoredBox(color: Colors.black54)),
        Positioned(left: 0, top: pr.bottom, right: 0, bottom: 0, child: const ColoredBox(color: Colors.black54)),
        Positioned(left: 0, top: pr.top, width: pr.left, height: pr.height, child: const ColoredBox(color: Colors.black54)),
        Positioned(left: pr.right, top: pr.top, right: 0, height: pr.height, child: const ColoredBox(color: Colors.black54)),
        Positioned.fromRect(
          rect: pr,
          child: IgnorePointer(
            child: Container(decoration: BoxDecoration(border: Border.all(color: accentColor, width: 2))),
          ),
        ),
        _handle(isLeft: true, isTop: true),
        _handle(isLeft: false, isTop: true),
        _handle(isLeft: true, isTop: false),
        _handle(isLeft: false, isTop: false),
      ],
    );
  }
}
