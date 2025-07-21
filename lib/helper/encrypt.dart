import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class AESHelper {
  // Key dan IV bebas, asalkan konsisten
  static final _keyBase64 = 'cGx1c0xHZ1ZRVjV0amQxNHBVNEU5ZzF6VXErY3J4V0k=';
  static final _ivBase64 = 'RU1zbXNxVWp0dGJmMGFReA==';

  static final _key = Key(base64.decode(_keyBase64));
  static final _iv = IV(base64.decode(_ivBase64));
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  static String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decryptData(String encryptedText) {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
  
}
