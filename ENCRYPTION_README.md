# Chat App Encryption Implementation

This document explains how to use the encryption features implemented in the Flutter frontend to work with your Node.js backend.

## Overview

The encryption system implements two types of encryption:

1. **Group Chat Encryption (AES)**: Symmetric encryption for group messages
2. **WebRTC Signaling Encryption (RSA)**: Asymmetric encryption for WebRTC signaling data

## Architecture

### Backend (Node.js)
- Creates symmetric keys for each group when the group is created
- Sends encrypted symmetric keys to clients
- Stores keys securely on the server

### Frontend (Flutter)
- Receives and stores group symmetric keys
- Encrypts/decrypts group messages using AES
- Handles WebRTC signaling encryption using RSA
- Manages key storage securely

## Services

### 1. EncryptionService (`lib/services/encryption_service.dart`)

The core encryption service that handles all cryptographic operations.

#### Key Features:
- **AES Encryption**: For group messages
- **RSA Key Generation**: For WebRTC signaling
- **Key Management**: Secure storage and retrieval
- **Message Integrity**: SHA-256 hashing for verification

#### Usage:

```dart
// Initialize the service
await EncryptionService.instance.initialize();

// Store a group key (received from server)
await EncryptionService.instance.storeGroupKey('group123', 'encrypted_key_from_server');

// Encrypt a group message
String encryptedMessage = EncryptionService.instance.encryptGroupMessage('group123', 'Hello World!');

// Decrypt a group message
String decryptedMessage = EncryptionService.instance.decryptGroupMessage('group123', encryptedMessage);

// Get public key for WebRTC signaling
String? publicKey = EncryptionService.instance.publicKey;
```

### 2. ChatService (`lib/services/chat_service.dart`)

High-level service that integrates encryption with socket communication.

#### Key Features:
- **Encrypted Message Sending**: Automatically encrypts messages before sending
- **Group Key Management**: Requests and stores group keys from server
- **Real-time Message Handling**: Processes incoming encrypted messages
- **Stream-based Updates**: Provides streams for UI updates

#### Usage:

```dart
// Initialize the service
await ChatService.instance.initialize();

// Join a group (automatically requests group key)
ChatService.instance.joinGroup('group123');

// Send encrypted message
bool success = await ChatService.instance.sendGroupMessage('group123', 'Hello World!');

// Listen for incoming messages
ChatService.instance.onGroupMessageReceived((groupId, message, fromUserId, timestamp) {
  print('Received: $message from user $fromUserId');
});

// Listen for group keys
ChatService.instance.onGroupKeyReceived((groupId, encryptedKey) {
  print('Group key received for: $groupId');
});
```

### 3. SocketClient (`lib/services/socket_client.dart`)

Enhanced socket client that handles encrypted communication.

#### New Methods:
- `sendGroupMessage()`: Sends encrypted group messages
- `onGroupMessage()`: Listens for encrypted group messages
- `requestGroupKey()`: Requests group key from server
- `onGroupKeyReceived()`: Listens for group key responses

## Integration with ViewModels

### ChatViewModel (`lib/view_models/chat/chat_viewmodel.dart`)

Updated to use encrypted messaging:

```dart
class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService.instance;

  ChatViewModel({required this.chatId, required this.currentUser}) {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _chatService.initialize();
    _chatService.joinGroup(chatId);
    
    // Set up listeners
    _chatService.onGroupMessageReceived((groupId, message, fromUserId, timestamp) {
      _handleEncryptedMessage(groupId, message, fromUserId, timestamp);
    });
  }

  Future<void> sendMessage(String text) async {
    final success = await _chatService.sendGroupMessage(chatId, text);
    if (!success) {
      // Message queued, waiting for group key
    }
  }
}
```

## WebRTC Integration

### WebRTCService (`lib/services/webrtc_service.dart`)

Enhanced to support encrypted signaling:

```dart
class WebRTCService {
  // Get public key for signaling
  String? get publicKey => EncryptionService.instance.publicKey;
}
```

The socket client automatically handles encryption/decryption of WebRTC signaling data.

## Socket Events

### Group Chat Events

#### Client → Server:
- `request_group_key`: Request group encryption key
- `group_message`: Send encrypted group message

#### Server → Client:
- `group_key`: Receive encrypted group key
- `group_message`: Receive encrypted group message

### WebRTC Events (Encrypted)

#### Client → Server:
- `offer`: Send encrypted WebRTC offer
- `answer`: Send encrypted WebRTC answer  
- `candidate`: Send encrypted ICE candidate

#### Server → Client:
- `getOffer`: Receive encrypted WebRTC offer
- `getAnswer`: Receive encrypted WebRTC answer
- `getCandidate`: Receive encrypted ICE candidate

## Message Format

### Group Messages
```json
{
  "groupId": "group123",
  "encryptedMessage": "base64_encrypted_data",
  "messageHash": "sha256_hash",
  "timestamp": 1640995200000
}
```

### WebRTC Signaling
```json
{
  "toUserId": 123,
  "encryptedPayload": "base64_encrypted_payload",
  "publicKey": "base64_public_key"
}
```

## Security Features

### 1. Key Management
- Group keys stored securely using `flutter_secure_storage`
- RSA private keys never leave the device
- Automatic key rotation support

### 2. Message Integrity
- SHA-256 hashing for message verification
- Prevents tampering with encrypted messages

### 3. Encryption Standards
- AES-256-CBC for group messages
- RSA-2048 for WebRTC signaling (simplified implementation)
- Secure random IV generation

## Testing

Use the `EncryptionExample` widget to test encryption features:

```dart
// Navigate to the example
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const EncryptionExample()),
);
```

## Backend Integration

Your backend should implement these endpoints:

### 1. Group Key Management
```javascript
// When group is created
socket.on('create_group', (data) => {
  const groupKey = generateSymmetricKey();
  const encryptedKey = encryptForUser(userId, groupKey);
  
  // Send to all group members
  groupMembers.forEach(member => {
    socket.to(member.id).emit('group_key', {
      groupId: groupId,
      encryptedKey: encryptedKey
    });
  });
});

// When user requests group key
socket.on('request_group_key', (data) => {
  const { groupId } = data;
  const groupKey = getGroupKey(groupId);
  const encryptedKey = encryptForUser(userId, groupKey);
  
  socket.emit('group_key', {
    groupId: groupId,
    encryptedKey: encryptedKey
  });
});
```

### 2. Message Handling
```javascript
// Handle encrypted group messages
socket.on('group_message', (data) => {
  const { groupId, encryptedMessage, messageHash, timestamp } = data;
  
  // Verify message integrity
  if (verifyMessageHash(encryptedMessage, messageHash)) {
    // Broadcast to group members
    socket.to(groupId).emit('group_message', {
      groupId: groupId,
      encryptedMessage: encryptedMessage,
      messageHash: messageHash,
      fromUserId: userId,
      timestamp: timestamp
    });
  }
});
```

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  encrypt: ^5.0.3
  crypto: ^3.0.3
  flutter_secure_storage: ^9.0.0
```

## Best Practices

1. **Always initialize encryption before using**: Call `EncryptionService.instance.initialize()` on app startup
2. **Handle missing keys gracefully**: Messages are queued when group keys aren't available
3. **Clear keys on logout**: Call `EncryptionService.instance.clearAllKeys()` when user logs out
4. **Monitor encryption status**: Check if encryption is ready before sending messages
5. **Test thoroughly**: Use the provided example to test encryption functionality

## Troubleshooting

### Common Issues:

1. **"Group key not found"**: Make sure to join the group first to request the key
2. **"Public key not available"**: Ensure encryption service is initialized
3. **"Message integrity check failed"**: Check if message was tampered with during transmission
4. **"Encryption error"**: Verify that the encryption dependencies are properly installed

### Debug Logging:

Enable debug logging to see encryption operations:

```dart
if (kDebugMode) {
  print('[Encryption] Operation details...');
}
```

## Future Enhancements

1. **Perfect Forward Secrecy**: Implement key rotation for group chats
2. **End-to-End Encryption**: Add client-side key verification
3. **Message Expiration**: Implement time-based message deletion
4. **Key Backup**: Secure key backup and recovery system
5. **Advanced RSA**: Implement proper RSA encryption library

This implementation provides a solid foundation for secure messaging in your chat application while maintaining compatibility with your existing backend architecture. 