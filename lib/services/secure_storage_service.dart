// lib/core/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class SecureStorageService {
  SecureStorageService._privateConstructor();
  static final SecureStorageService instance = SecureStorageService._privateConstructor();

  final _storage = const FlutterSecureStorage();

  // Auth token methods
  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.authToken);
  }

  // Private key methods
  Future<void> savePrivateKey(String privateKey) async {
    await _storage.write(key: StorageKeys.privateKey, value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: StorageKeys.privateKey);
  }

  Future<void> deletePrivateKey() async {
    await _storage.delete(key: StorageKeys.privateKey);
  }

  // Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}