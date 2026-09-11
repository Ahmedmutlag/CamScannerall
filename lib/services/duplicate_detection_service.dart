import '../models/document.dart';
import 'database_service.dart';

/// Detects likely-duplicate documents by comparing their OCR-extracted
/// text (never the raw image), and only within the same folder — this
/// avoids false positives between visually similar documents that differ
/// in the numbers/dates they contain (e.g. two different invoices).
class DuplicateDetectionService {
  DuplicateDetectionService(this._db);

  final DatabaseService _db;

  static const double similarityThreshold = 0.88;

  Document? findLikelyDuplicate(Document candidate) {
    final candidateTokens = _tokenize(candidate.extractedText);
    if (candidateTokens.isEmpty) return null;

    for (final other in _db.documentsForFolder(candidate.folderId)) {
      if (other.id == candidate.id) continue;
      final otherTokens = _tokenize(other.extractedText);
      if (otherTokens.isEmpty) continue;
      final similarity = _jaccard(candidateTokens, otherTokens);
      if (similarity >= similarityThreshold) {
        return other;
      }
    }
    return null;
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.trim().isNotEmpty)
        .toSet();
  }

  double _jaccard(Set<String> a, Set<String> b) {
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    if (union == 0) return 0;
    return intersection / union;
  }
}
