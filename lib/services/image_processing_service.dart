import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Visual filter applied to a scanned page.
enum ScanFilter { original, blackAndWhite, color, auto }

/// All image manipulation (perspective correction, filters, resizing) is
/// done fully on-device using the pure-Dart `image` package, and heavy
/// work always runs on a background isolate via [compute] so the UI never
/// freezes.
class ImageProcessingService {
  // 300dpi — the standard target for sharp, OCR-grade text scans (the
  // previous ~200dpi was visibly softer once printed or zoomed into).
  static const int a4WidthPx = 2481; // 300dpi at A4 width (8.27in)
  static const int a4HeightPx = 3508; // 300dpi at A4 height (11.69in)
  static const int lowResMaxDimension = 900;

  /// Processes a freshly captured/imported photo: applies perspective
  /// correction (if [corners] given), the chosen [filter], then writes a
  /// high-res A4-normalized JPEG and a light low-res JPEG for quick share.
  ///
  /// Returns the two output file paths.
  Future<(String highResPath, String lowResPath)> processAndSave({
    required String sourcePath,
    required String outputDir,
    required String pageId,
    List<Offset>? corners,
    ScanFilter filter = ScanFilter.auto,
  }) async {
    final result = await compute(_processImageIsolate, {
      'sourcePath': sourcePath,
      'corners': corners
          ?.map((o) => [o.dx, o.dy])
          .toList(growable: false),
      'filter': filter.index,
    });

    final highResBytes = result['high'] as Uint8List;
    final lowResBytes = result['low'] as Uint8List;

    final highPath = '$outputDir/${pageId}_hi.jpg';
    final lowPath = '$outputDir/${pageId}_lo.jpg';
    await File(highPath).writeAsBytes(highResBytes);
    await File(lowPath).writeAsBytes(lowResBytes);

    return (highPath, lowPath);
  }

  /// Re-processes an already-saved high-res page image with a new filter
  /// choice (used when the user changes the filter after capture).
  Future<void> reapplyFilter({
    required String highResPath,
    required String lowResPath,
    required ScanFilter filter,
  }) async {
    final result = await compute(_processImageIsolate, {
      'sourcePath': highResPath,
      'corners': null,
      'filter': filter.index,
      'skipRectify': true,
    });
    await File(highResPath).writeAsBytes(result['high'] as Uint8List);
    await File(lowResPath).writeAsBytes(result['low'] as Uint8List);
  }

  /// Rotates an already-saved page by [quarterTurns] * 90° clockwise,
  /// rewriting both the high-res file and its low-res thumbnail in place.
  Future<void> rotateSavedPage({
    required String highResPath,
    required String lowResPath,
    int quarterTurns = 1,
  }) async {
    final result = await compute(_rotateIsolate, {
      'highResPath': highResPath,
      'degrees': (quarterTurns % 4) * 90,
    });
    await File(highResPath).writeAsBytes(result['high'] as Uint8List);
    await File(lowResPath).writeAsBytes(result['low'] as Uint8List);
  }

  /// Trims an already-saved page down to [rect] (fractions of the image's
  /// width/height, 0..1) — a manual touch-up for when the scanner's own
  /// automatic crop left in a margin or a bit of the surface underneath.
  Future<void> cropSavedPage({
    required String highResPath,
    required String lowResPath,
    required Rect rect,
  }) async {
    final result = await compute(_cropIsolate, {
      'highResPath': highResPath,
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    });
    await File(highResPath).writeAsBytes(result['high'] as Uint8List);
    await File(lowResPath).writeAsBytes(result['low'] as Uint8List);
  }
}

Map<String, Uint8List> _rotateIsolate(Map<String, dynamic> params) {
  final highResPath = params['highResPath'] as String;
  final degrees = params['degrees'] as int;

  var image = img.decodeImage(File(highResPath).readAsBytesSync());
  if (image == null) throw Exception('Could not decode image at $highResPath');
  if (degrees != 0) {
    image = img.copyRotate(image, angle: degrees);
  }
  return _encodeHighAndLow(image);
}

Map<String, Uint8List> _cropIsolate(Map<String, dynamic> params) {
  final highResPath = params['highResPath'] as String;
  final left = params['left'] as double;
  final top = params['top'] as double;
  final width = params['width'] as double;
  final height = params['height'] as double;

  final image = img.decodeImage(File(highResPath).readAsBytesSync());
  if (image == null) throw Exception('Could not decode image at $highResPath');

  final cropped = img.copyCrop(
    image,
    x: (left * image.width).round().clamp(0, image.width - 1),
    y: (top * image.height).round().clamp(0, image.height - 1),
    width: (width * image.width).round().clamp(1, image.width),
    height: (height * image.height).round().clamp(1, image.height),
  );
  return _encodeHighAndLow(cropped);
}

Map<String, Uint8List> _encodeHighAndLow(img.Image image) {
  // Quality bumped from 92 — at the higher working resolution below, 92
  // started showing visible JPEG blocking on fine text; 95 keeps files a
  // reasonable size while avoiding that softening.
  final highJpg = img.encodeJpg(image, quality: 95);

  final lowScale = ImageProcessingService.lowResMaxDimension /
      (image.width > image.height ? image.width : image.height);
  final lowImage = lowScale < 1.0
      ? img.copyResize(
          image,
          width: (image.width * lowScale).round(),
          height: (image.height * lowScale).round(),
        )
      : image;
  final lowJpg = img.encodeJpg(lowImage, quality: 55);

  return {
    'high': Uint8List.fromList(highJpg),
    'low': Uint8List.fromList(lowJpg),
  };
}

Map<String, Uint8List> _processImageIsolate(Map<String, dynamic> params) {
  final sourcePath = params['sourcePath'] as String;
  final cornersRaw = params['corners'] as List?;
  final filterIndex = params['filter'] as int;
  final filter = ScanFilter.values[filterIndex];

  final bytes = File(sourcePath).readAsBytesSync();
  var image = img.decodeImage(bytes);
  if (image == null) {
    throw Exception('Could not decode image at $sourcePath');
  }

  // Respect EXIF orientation before any further processing.
  image = img.bakeOrientation(image);

  if (cornersRaw != null && cornersRaw.length == 4) {
    final pts = cornersRaw
        .map((c) => img.Point((c as List)[0] as double, c[1] as double))
        .toList();
    image = img.copyRectify(
      image,
      topLeft: pts[0],
      topRight: pts[1],
      bottomRight: pts[2],
      bottomLeft: pts[3],
      interpolation: img.Interpolation.linear,
    );
  }

  // Normalize onto an A4-proportioned canvas without distorting content:
  // scale to fit within the A4 pixel box, preserving aspect ratio.
  final targetW = ImageProcessingService.a4WidthPx;
  final targetH = ImageProcessingService.a4HeightPx;
  final scale = (targetW / image.width < targetH / image.height)
      ? targetW / image.width
      : targetH / image.height;
  if (scale < 1.0) {
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  image = _applyFilter(image, filter);

  return _encodeHighAndLow(image);
}

/// A light sharpening kernel — cheap to run, and makes scanned text noticeably
/// crisper without the halo artifacts a stronger unsharp mask would add.
const _sharpenKernel = [0, -1, 0, -1, 5, -1, 0, -1, 0];

img.Image _applyFilter(img.Image image, ScanFilter filter) {
  switch (filter) {
    case ScanFilter.original:
      return image;
    case ScanFilter.color:
      final adjusted = img.adjustColor(image, contrast: 1.08, saturation: 1.1, brightness: 1.02);
      return img.convolution(adjusted, filter: _sharpenKernel);
    case ScanFilter.blackAndWhite:
      // Normalizing first (per-image contrast stretch) makes the fixed
      // threshold below hold up across uneven lighting/shadows, instead of
      // only working well on already well-lit photos.
      final normalized = img.normalize(image, min: 0, max: 255);
      final gray = img.grayscale(normalized);
      return img.luminanceThreshold(gray, threshold: 0.56);
    case ScanFilter.auto:
      // Adaptive per-image contrast stretch (handles a shadowed corner or a
      // dim photo far better than a fixed brightness/contrast bump would),
      // a small color touch-up, then a light sharpen for crisper text —
      // closer to what a dedicated scanner app's "enhance" mode does.
      final normalized = img.normalize(image, min: 0, max: 255);
      final adjusted = img.adjustColor(normalized, contrast: 1.08, brightness: 1.04, saturation: 0.97);
      return img.convolution(adjusted, filter: _sharpenKernel);
  }
}
