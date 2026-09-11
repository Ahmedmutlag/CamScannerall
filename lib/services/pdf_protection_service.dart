import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Password-protects an exported PDF with real, PDF-standard-security
/// encryption (AES-256), via Syncfusion's PDF library. Unlike an
/// app-private encrypted container, the result is a normal .pdf file that
/// any standard PDF reader (Adobe Acrobat, Google Drive preview, etc.)
/// will prompt for the password before opening — see the README's
/// "حماية PDF بكلمة سر" section for the licensing terms this depends on
/// (Syncfusion's free Community License).
class PdfProtectionService {
  /// Re-encodes [pdfBytes] with [password] as both the open (user) and
  /// permissions (owner) password, using AES-256.
  Future<Uint8List> protect(Uint8List pdfBytes, String password) async {
    final document = PdfDocument(inputBytes: pdfBytes);
    document.security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    document.security.userPassword = password;
    document.security.ownerPassword = password;
    final bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }
}
