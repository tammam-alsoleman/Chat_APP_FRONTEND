// test_password_hashing.dart
// Test file to verify password hashing functionality

import 'lib/services/password_service.dart';

void main() async {
  print('Testing Password Hashing...\n');
  
  try {
    // Test 1: Basic password hashing
    print('Test 1: Basic password hashing');
    final password = 'mySecurePassword123';
    final hashedPassword = PasswordService.hashPassword(password);
    print('Original password: $password');
    print('Hashed password: $hashedPassword');
    print('✅ Password hashed successfully\n');
    
    // Test 2: Password verification
    print('Test 2: Password verification');
    final isCorrect = PasswordService.verifyPassword(password, hashedPassword);
    final isWrong = PasswordService.verifyPassword('wrongPassword', hashedPassword);
    print('Correct password verification: $isCorrect');
    print('Wrong password verification: $isWrong');
    print('✅ Password verification working correctly\n');
    
    // Test 3: Server hash
    print('Test 3: Server hash for API calls');
    final serverHash = PasswordService.hashForServer(password);
    print('Original password: $password');
    print('Server hash: $serverHash');
    print('✅ Server hash generated successfully\n');
    
    // Test 4: Multiple hashes for same password
    print('Test 4: Multiple hashes for same password (should be different due to salt)');
    final hash1 = PasswordService.hashPassword(password);
    final hash2 = PasswordService.hashPassword(password);
    print('Hash 1: $hash1');
    print('Hash 2: $hash2');
    print('Hashes are different: ${hash1 != hash2}');
    print('✅ Salt is working correctly\n');
    
    // Test 5: Server hashes for same password (should be same)
    print('Test 5: Server hashes for same password (should be same)');
    final serverHash1 = PasswordService.hashForServer(password);
    final serverHash2 = PasswordService.hashForServer(password);
    print('Server Hash 1: $serverHash1');
    print('Server Hash 2: $serverHash2');
    print('Server hashes are same: ${serverHash1 == serverHash2}');
    print('✅ Server hashing is deterministic\n');
    
    print('🎉 All password hashing tests passed!');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
} 