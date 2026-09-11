import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import 'storage_paths.dart';

/// Handles the reusable hand-drawn signature ("my signature") and stamping
/// it onto scanned pages. All composition happens on-device with the
/// `image` package.
class SignatureService {
  static const _fileName = 'my_signature.png';

  Future<bool> hasSavedSignature() async {
    final dir = await StoragePaths.signaturesDirectory();
    return File('${dir.path}/$_fileName').exists();
  }

  Future<String> savedSignaturePath() async {
    final dir = await StoragePaths.signaturesDirectory();
    return '${dir.path}/$_fileName';
  }

  Future<void> saveMySignature(Uint8List pngBytes) async {
    final path = await savedSignaturePath();
    await File(path).writeAsBytes(pngBytes);
  }

  /// Stamps the given signature PNG onto a copy of [pageImagePath].
  /// [relativeOffset] and [relativeWidth] are expressed as fractions
  /// (0.0-1.0) of the page image's width/height, so the caller doesn't
  /// need to know the underlying pixel resolution.
  Future<void> applySignatureToPage({
    required String highResPath,
    required String lowResPath,
    required Uint8List signaturePng,
    required Offset relativeOffset,
    required double relativeWidth,
    bool addDateStamp = false,
  }) async {
    await compute(_stampIsolate, {
      'highResPath': highResPath,
      'lowResPath': lowResPath,
      'signaturePng': signaturePng,
      'dx': relativeOffset.dx,
      'dy': relativeOffset.dy,
      'relativeWidth': relativeWidth,
      'addDateStamp': addDateStamp,
      'dateText': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });
  }
}

void _stampIsolate(Map<String, dynamic> params) {
  final highResPath = params['highResPath'] as String;
  final lowResPath = params['lowResPath'] as String;
  final signatureBytes = params['signaturePng'] as Uint8List;
  final dx = params['dx'] as double;
  final dy = params['dy'] as double;
  final relativeWidth = params['relativeWidth'] as double;
  final addDateStamp = params['addDateStamp'] as bool;
  final dateText = params['dateText'] as String;

  for (final path in [highResPath, lowResPath]) {
    final page = img.decodeImage(File(path).readAsBytesSync());
    final signature = img.decodeImage(signatureBytes);
    if (page == null || signature == null) continue;

    final targetWidth = (page.width * relativeWidth).round().clamp(20, page.width);
    final scale = targetWidth / signature.width;
    final targetHeight = (signature.height * scale).round();
    final resizedSignature = img.copyResize(signature, width: targetWidth, height: targetHeight);

    final x = (page.width * dx).round();
    final y = (page.height * dy).round();

    img.compositeImage(page, resizedSignature, dstX: x, dstY: y);

    if (addDateStamp) {
      img.drawString(
        page,
        dateText,
        font: img.arial24,
        x: x,
        y: y + targetHeight + 4,
        color: img.ColorRgb8(20, 20, 20),
      );
    }

    final outBytes = img.encodeJpg(page, quality: path == highResPath ? 92 : 55);
    File(path).writeAsBytesSync(outBytes);
  }
}
