import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'encryption_key'; // Store this securely in production
  static late final encrypt.Key _encryptionKey;
  static late final encrypt.IV _iv;
  static late final encrypt.Encrypter _encrypter;

  // Initialize encryption
  static Future<void> initialize() async {
    // Generate or retrieve encryption key
    String? storedKey = await _storage.read(key: _key);
    if (storedKey == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _storage.write(key: _key, value: key.base64);
      _encryptionKey = key;
    } else {
      _encryptionKey = encrypt.Key.fromBase64(storedKey);
    }

    // Initialize IV and encrypter
    _iv = encrypt.IV.fromSecureRandom(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
  }

  // Store encrypted data
  static Future<void> storeSecureData(String key, String value) async {
    try {
      final encrypted = _encrypter.encrypt(value, iv: _iv);
      await _storage.write(key: key, value: encrypted.base64);
    } catch (e) {
      print('Error storing secure data: $e');
      rethrow;
    }
  }

  // Retrieve and decrypt data
  static Future<String?> getSecureData(String key) async {
    try {
      final encryptedValue = await _storage.read(key: key);
      if (encryptedValue == null) return null;

      final encrypted = encrypt.Encrypted.fromBase64(encryptedValue);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Error retrieving secure data: $e');
      return null;
    }
  }

  // Delete secure data
  static Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('Error deleting secure data: $e');
      rethrow;
    }
  }

  // Store sensitive user data
  static Future<void> storeUserData({
    required String userId,
    required String email,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      final userData = {
        'userId': userId,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
      };

      await storeSecureData('user_data', jsonEncode(userData));
    } catch (e) {
      print('Error storing user data: $e');
      rethrow;
    }
  }

  // Retrieve user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final data = await getSecureData('user_data');
      if (data == null) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error retrieving user data: $e');
      return null;
    }
  }

  // Store API keys or tokens
  static Future<void> storeApiKey(String key, String value) async {
    try {
      await storeSecureData('api_key_$key', value);
    } catch (e) {
      print('Error storing API key: $e');
      rethrow;
    }
  }

  // Retrieve API key
  static Future<String?> getApiKey(String key) async {
    try {
      return await getSecureData('api_key_$key');
    } catch (e) {
      print('Error retrieving API key: $e');
      return null;
    }
  }

  // Clear all secure data
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('Error clearing secure data: $e');
      rethrow;
    }
  }
} 