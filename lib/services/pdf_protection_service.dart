
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';

import 'crypto_helper.dart';

/// Password-protects an exported PDF using the same on-device AES-256
/// primitives as the backup feature. The result is an app-level encrypted
/// container (`.pdf.enc`): only this app (with the right password) can
/// decrypt it back into the original PDF. This keeps every crypto path in
/// the app consistent and fully local, with no dependency on a raw
/// PDF-standard-security implementation.
class PdfProtectionService {
  static const List<int> _magic = [0x50, 0x44, 0x46, 0x31]; // "PDF1"

  Future<Uint8List> protect(Uint8List pdfBytes, String password) {
    return compute(_encrypt, {'password': password, 'data': pdfBytes});
  }

  /// Throws [FormatException] if the password is wrong or the file is
  /// corrupted.
  Future<Uint8List> unprotect(Uint8List protectedBytes, String password) {
    return compute(_decrypt, {'password': password, 'data': protectedBytes});
  }

  static Uint8List _encrypt(Map<String, dynamic> params) {
    final password = params['password'] as String;
    final data = params['data'] as Uint8List;

    final salt = CryptoHelper.randomBytes(CryptoHelper.saltLength);
    final iv = CryptoHelper.randomBytes(CryptoHelper.ivLength);
    final key = CryptoHelper.deriveKey(password, salt);
    final ciphertext = CryptoHelper.encryptAesCbc(key: key, iv: iv, plaintext: data);
    final macKey = Uint8List.fromList(crypto.sha256.convert([...key, ..."MAC".codeUnits]).bytes);
    final mac = CryptoHelper.hmac(macKey, ciphertext);

    return Uint8List.fromList([..._magic, ...salt, ...iv, ...mac, ...ciphertext]);
  }

  static Uint8List _decrypt(Map<String, dynamic> params) {
    final password = params['password'] as String;
    final data = params['data'] as Uint8List;

    var offset = 4;
    final salt = data.sublist(offset, offset + CryptoHelper.saltLength);
    offset += CryptoHelper.saltLength;
    final iv = data.sublist(offset, offset + CryptoHelper.ivLength);
    offset += CryptoHelper.ivLength;
    final mac = data.sublist(offset, offset + 32);
    offset += 32;
    final ciphertext = data.sublist(offset);

    final key = CryptoHelper.deriveKey(password, Uint8List.fromList(salt));
    final macKey = Uint8List.fromList(crypto.sha256.convert([...key, ..."MAC".codeUnits]).bytes);
    final expectedMac = CryptoHelper.hmac(macKey, Uint8List.fromList(ciphertext));

    var ok = expectedMac.length == mac.length;
    if (ok) {
      for (var i = 0; i < mac.length; i++) {
        if (expectedMac[i] != mac[i]) {
          ok = false;
          break;
        }
      }
    }
    if (!ok) throw const FormatException('Wrong password or corrupted file');

    return CryptoHelper.decryptAesCbc(
      key: key,
      iv: Uint8List.fromList(iv),
      ciphertext: Uint8List.fromList(ciphertext),
    );
  }
}
