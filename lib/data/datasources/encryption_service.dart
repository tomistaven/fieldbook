import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256 in the encrypt package's default SIC (counter) mode, with a
/// random IV per value. The key lives in the Android Keystore via
/// flutter_secure_storage.
class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  final _secureStorage = const FlutterSecureStorage();

  late encrypt.Encrypter _encrypter;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    String? storedKey;
    try {
      storedKey = await _secureStorage.read(key: _keyStorageKey);
    } catch (_) {
      // Keystore entries can survive uninstall and become unreadable.
      await _secureStorage.delete(key: _keyStorageKey);
      storedKey = null;
    }

    final encrypt.Key key;
    if (storedKey == null) {
      key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(key: _keyStorageKey, value: key.base64);
    } else {
      key = encrypt.Key.fromBase64(storedKey);
    }

    _encrypter = encrypt.Encrypter(encrypt.AES(key));
    _isInitialized = true;
  }

  /// Returns `<base64 IV>:<base64 ciphertext>`, or '' for empty input.
  String encryptText(String plainText) {
    _ensureInitialized();
    if (plainText.isEmpty) return '';
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Inverse of [encryptText]. Returns '' on malformed input or wrong key.
  String decryptText(String encryptedText) {
    _ensureInitialized();
    if (encryptedText.isEmpty) return '';
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return '';
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return '';
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized. Call init() first.');
    }
  }
}