// lib/services/password_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordService {
  static const String _saltChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const int _saltLength = 16;
  static const int _iterations = 10000;

  /// Generates a random salt for password hashing
  static String _generateSalt() {
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(_saltLength, (_) => _saltChars.codeUnitAt(random.nextInt(_saltChars.length)))
    );
  }

  /// Hashes a password with a salt using SHA-256
  /// Returns the hash in format: salt:hash
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = _hashWithSalt(password, salt);
    return '$salt:$hash';
  }

  /// Verifies a password against a stored hash
  /// The stored hash should be in format: salt:hash
  static bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) {
        return false;
      }
      
      final salt = parts[0];
      final storedPasswordHash = parts[1];
      final computedHash = _hashWithSalt(password, salt);
      
      return storedPasswordHash == computedHash;
    } catch (e) {
      return false;
    }
  }

  /// Internal method to hash password with salt
  static String _hashWithSalt(String password, String salt) {
    String hash = password + salt;
    
    // Apply multiple iterations for better security
    for (int i = 0; i < _iterations; i++) {
      final bytes = utf8.encode(hash);
      final digest = sha256.convert(bytes);
      hash = digest.toString();
    }
    
    return hash;
  }

  /// Creates a hash for server communication (without salt for API calls)
  /// This is used when sending password to server for authentication
  /// Returns a shorter hash (first 40 characters) to fit database constraints
  static String hashForServer(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final fullHash = digest.toString();
    
    // Return first 40 characters to fit database column size
    // This still provides good security while being compatible
    return fullHash.substring(0, 40);
  }
} 