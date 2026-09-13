import 'package:gal/gal.dart';

/// Explicit, user-initiated export of scanned pages to the phone's public
/// photo gallery. Everything else in the app stays inside its private
/// sandbox by design (see PRIVACY_POLICY.md) — this is the one deliberate
/// opt-in path for a document the user wants to treat like an ordinary
/// photo (open it from Photos, back it up via their normal photo backup,
/// share it to an app that only accepts gallery images...). It never runs
/// on its own; only a user tapping "Save to gallery" triggers it.
class GalleryService {
  Future<void> saveImages(List<String> paths, {required String album}) async {
    for (final path in paths) {
      await Gal.putImage(path, album: album);
    }
  }
}
