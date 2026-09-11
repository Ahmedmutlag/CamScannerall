import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as imglib;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'image_processing_service.dart';

/// Builds, splits, compresses and exports PDF documents from a document's
/// scanned page images. Pages are always laid out on a standard A4 sheet
/// per the product spec, instead of raw camera dimensions.
class PdfService {
  /// Builds a single multi-page A4 PDF from the given high-resolution page
  /// image paths. Runs off the UI thread.
  Future<Uint8List> buildPdf(List<String> imagePaths) {
    return compute(_buildPdfIsolate, imagePaths);
  }

  Future<String> savePdf(Uint8List bytes, String path) async {
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  /// Produces a compressed copy of the pages (smaller JPEG quality/size)
  /// and rebuilds the PDF, aiming for a smaller output file with minimal
  /// visible quality loss.
  Future<Uint8List> compressPdf(List<String> imagePaths) {
    return compute(_compressAndBuildIsolate, imagePaths);
  }

  /// Prints the given PDF bytes to a nearby WiFi/Bluetooth printer.
  Future<void> printBytes(Uint8List bytes, {String name = 'document'}) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
  }

  /// Opens the OS share sheet with the PDF bytes attached.
  Future<void> sharePdf(Uint8List bytes, {String filename = 'document.pdf'}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

Future<Uint8List> _buildPdfIsolate(List<String> imagePaths) async {
  final doc = pw.Document();
  for (final path in imagePaths) {
    final bytes = File(path).readAsBytesSync();
    final image = pw.MemoryImage(bytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  return doc.save();
}

Future<Uint8List> _compressAndBuildIsolate(List<String> imagePaths) async {
  final doc = pw.Document();
  for (final path in imagePaths) {
    final original = File(path).readAsBytesSync();
    final compressedBytes = _recompressJpeg(original);
    final image = pw.MemoryImage(compressedBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  return doc.save();
}

Uint8List _recompressJpeg(Uint8List sourceBytes) {
  // Re-encode through the image package at reduced quality and, if large,
  // reduced resolution — a simple, dependency-light way to shrink the PDF.
  final decoded = imglib.decodeImage(sourceBytes);
  if (decoded == null) return sourceBytes;
  var resized = decoded;
  const maxDim = ImageProcessingService.a4WidthPx;
  if (decoded.width > maxDim || decoded.height > maxDim) {
    final scale = maxDim / (decoded.width > decoded.height ? decoded.width : decoded.height);
    resized = imglib.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
    );
  }
  return Uint8List.fromList(imglib.encodeJpg(resized, quality: 60));
}
