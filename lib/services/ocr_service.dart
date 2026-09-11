import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition (Arabic + English) via Google ML Kit.
/// Everything runs locally on the device — ML Kit's on-device text
/// recognizer never uploads images anywhere.
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  /// Extracts text from every page and joins it, used to build the
  /// document's searchable `extractedText` field and to suggest a name.
  Future<String> extractTextFromPages(List<String> imagePaths) async {
    final buffer = StringBuffer();
    for (final path in imagePaths) {
      final text = await extractText(path);
      if (text.trim().isNotEmpty) {
        buffer.writeln(text.trim());
      }
    }
    return buffer.toString().trim();
  }

  /// Suggests a short document name from the first non-empty line of
  /// recognized text, falling back to a timestamp-based name.
  String suggestName(String extractedText, {String fallback = 'مستند'}) {
    final lines = extractedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length >= 3)
        .toList();
    if (lines.isEmpty) return fallback;
    var candidate = lines.first;
    if (candidate.length > 40) candidate = candidate.substring(0, 40);
    return candidate;
  }

  void dispose() {
    _recognizer.close();
  }
}
