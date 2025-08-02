// lib/services/crypto_service.dart
import 'dart:convert';
import 'package:fast_rsa/fast_rsa.dart' as rsa;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class CryptoService {
  final _storage = const FlutterSecureStorage();

  // --- ASYMMETRIC (RSA) for Key Exchange ---

  /// Generates a new RSA key pair using fast_rsa.
  Future<String> generateAndStoreKeyPair() async {
    final keyPair = await rsa.RSA.generate(2048);
    await _storage.write(key: StorageKeys.privateKey, value: keyPair.privateKey);
    return keyPair.publicKey; // Returns public key in PEM format
  }

  /// Encrypts a plaintext string (the symmetric group key) with a public key.
  Future<String> encryptWithPublicKey(String plainText, String publicKeyPem) async {
    return await rsa.RSA.encryptPKCS1v15(plainText, publicKeyPem);
  }

  /// Decrypts an incoming encrypted group key using our stored private key.
  Future<String> decryptWithPrivateKey(String base64CipherText) async {
    final privateKeyPem = await _storage.read(key: StorageKeys.privateKey);
    if (privateKeyPem == null) {
      throw Exception("Private key not found for decryption.");
    }
    return await rsa.RSA.decryptPKCS1v15(base64CipherText, privateKeyPem);
  }


  // --- SYMMETRIC (AES) for Message Encryption ---

  /// Generates a new random AES key (32 bytes for AES-256).
  enc.Key newSymmetricKey() {
    return enc.Key.fromSecureRandom(32);
  }

  /// Encrypts a message with an AES key.
  /// The IV (Initialization Vector) is prepended to the ciphertext for use in decryption.
  String encryptSymmetric(String plainText, enc.Key key) {
    // A new, random IV must be generated for every encryption.
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key)); // Using default AES (CBC mode)
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Return the IV and ciphertext together, separated by a colon.
    return "${iv.base64}:${encrypted.base64}";
  }

  /// Decrypts a message with an AES key.
  String decryptSymmetric(String encryptedPayload, enc.Key key) {
    try {
      final parts = encryptedPayload.split(':');
      if (parts.length != 2) throw const FormatException("Invalid encrypted payload format");

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = parts[1];

      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.decrypt64(encryptedData, iv: iv);
    } catch (e) {
      print("Decryption failed: $e");
      return "Unable to decrypt message."; // Return a safe fallback message
    }
  }
}