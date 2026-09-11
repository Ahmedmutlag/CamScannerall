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
  static const int a4WidthPx = 1654; // ~200dpi at A4 width (8.27in)
  static const int a4HeightPx = 2339; // ~200dpi at A4 height (11.69in)
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

  final highJpg = img.encodeJpg(image, quality: 92);

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

img.Image _applyFilter(img.Image image, ScanFilter filter) {
  switch (filter) {
    case ScanFilter.original:
      return image;
    case ScanFilter.color:
      return img.adjustColor(image, contrast: 1.08, saturation: 1.1, brightness: 1.02);
    case ScanFilter.blackAndWhite:
      final gray = img.grayscale(image);
      return img.luminanceThreshold(gray, threshold: 0.56);
    case ScanFilter.auto:
      // Boost contrast and brightness to fade shadows/backgrounds while
      // keeping the image readable in color — a reasonable on-device
      // approximation of "clean background & remove shadow".
      return img.adjustColor(image, contrast: 1.25, brightness: 1.08, saturation: 0.95);
  }
}
