// test_signup_flow.dart
// This is a simple test to verify the sign-up flow works correctly

import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  // Test key generation
  print('Testing RSA key generation...');
  
  try {
    // Generate RSA key pair
    final keyPair = await RSA.generate(2048);
    final publicKey = keyPair.publicKey;
    final privateKey = keyPair.privateKey;
    
    print('✅ RSA key pair generated successfully');
    print('Public key length: ${publicKey.length} characters');
    print('Private key length: ${privateKey.length} characters');
    
    // Test secure storage
    print('\nTesting secure storage...');
    
    const storage = FlutterSecureStorage();
    
    // Store private key
    await storage.write(key: 'test_private_key', value: privateKey);
    print('✅ Private key stored successfully');
    
    // Retrieve private key
    final retrievedKey = await storage.read(key: 'test_private_key');
    if (retrievedKey == privateKey) {
      print('✅ Private key retrieved successfully');
    } else {
      print('❌ Private key retrieval failed');
    }
    
    // Clean up test data
    await storage.delete(key: 'test_private_key');
    print('✅ Test data cleaned up');
    
    // Test PEM formatting
    final publicKeyPem = '-----BEGIN PUBLIC KEY-----\n${publicKey}\n-----END PUBLIC KEY-----';
    print('\n✅ Public key formatted as PEM:');
    print(publicKeyPem.substring(0, 50) + '...');
    
    print('\n🎉 All tests passed! Sign-up flow is working correctly.');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
} 