import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

/// Shared AES-256 encryption primitives used by both the backup export/
/// import feature and PDF password protection. Everything runs on-device;
/// keys are derived from a user-supplied password via PBKDF2 and never
/// stored anywhere.
class CryptoHelper {
  static const int saltLength = 16;
  static const int ivLength = 16;
  static const int keyLength = 32; // AES-256
  static const int pbkdf2Iterations = 20000;

  static Uint8List randomBytes(int length) {
    final rand = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rand.nextInt(256)));
  }

  /// Derives a 256-bit key from [password] and [salt] using PBKDF2-HMAC-SHA256.
  /// This is CPU-heavy by design (brute-force resistance) — call it from a
  /// background isolate.
  static Uint8List deriveKey(String password, Uint8List salt) {
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, pbkdf2Iterations, keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List hmac(Uint8List key, Uint8List data) {
    final mac = crypto.Hmac(crypto.sha256, key);
    return Uint8List.fromList(mac.convert(data).bytes);
  }

  static Uint8List encryptAesCbc({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List plaintext,
  }) {
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    final result = encrypter.encryptBytes(plaintext, iv: enc.IV(iv));
    return Uint8List.fromList(result.bytes);
  }

  static Uint8List decryptAesCbc({
    required Uint8List key,
    required Uint8List iv,
    required Uint8List ciphertext,
  }) {
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    final result = encrypter.decryptBytes(enc.Encrypted(ciphertext), iv: enc.IV(iv));
    return Uint8List.fromList(result);
  }
}
