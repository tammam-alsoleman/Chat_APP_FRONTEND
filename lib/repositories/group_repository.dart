// lib/repositories/group_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/crypto_service.dart';
import '../services/socket_client.dart';
import '../services/locator.dart';
import '../shared/utils.dart';
import '../services/chat_security_service.dart';

class GroupRepository {
  final CryptoService _cryptoService = sl<CryptoService>();
  final io.Socket _socket = sl<SocketClient>().socket;
  final ChatSecurityService _securityService = sl<ChatSecurityService>();

  /// Orchestrates the E2EE group creation flow. The server now generates the groupId.
  /// Returns the new, database-generated group's ID as a String.
  Future<String> createEncryptedGroup(List<int> participantUserIds) async {
    final completer = Completer<String>();

    // ===== REVERTED LOGIC: Client generates the ID =====
    final String tempGroupId = DateTime.now().millisecondsSinceEpoch.toString();
    // =================================================

    AppUtils.log('[GroupRepo] Emitting "initiate_group_creation" with IDs: $participantUserIds');

    _socket.emitWithAck('initiate_group_creation', {
      'participantUserIds': participantUserIds
    }, ack: (response) async {
      AppUtils.log('[GroupRepo] Public keys response: $response');
      if (response['success'] == true && response['publicKeys'] != null) {
        try {
          final Map<String, dynamic> publicKeysMap = response['publicKeys'];
          final groupKey = _cryptoService.newSymmetricKey();
          final groupKeyString = base64Encode(groupKey.bytes);

          // Store the key immediately with our temporary ID.
          _securityService.storeKey(tempGroupId, groupKey);

          Map<String, String> encryptedKeys = {};
          for (var userId in publicKeysMap.keys) {
            final publicKeyPem = publicKeysMap[userId] as String;
            encryptedKeys[userId] = await _cryptoService.encryptWithPublicKey(groupKeyString, publicKeyPem);
          }

          // Distribute the encrypted keys, INCLUDING the groupId.
          _socket.emit('distribute_encrypted_keys', {
            'groupId': int.parse(tempGroupId), // Send as an integer
            'encryptedKeys': encryptedKeys,
          });

          AppUtils.log('[GroupRepo] Group $tempGroupId created and keys distributed.');
          // Complete the future immediately. The client assumes success.
          completer.complete(tempGroupId);

        } catch (e) {
          completer.completeError('Failed to process and encrypt keys: $e');
        }
      } else {
        completer.completeError(response['error'] ?? 'Failed to get public keys.');
      }
    });

    return completer.future;
  }

  /// Listens for incoming group keys for chats we've been added to.
  void listenForGroupKeys() {
    _socket.off('receive_group_key'); // Avoid duplicate listeners
    _socket.on('receive_group_key', (data) async {
      AppUtils.log('[GroupRepo] Received new group key: $data');
      try {
        final Map<String, dynamic> keyData = (data is List) ? data[0] : data;
        final String groupId = keyData['groupId'].toString();
        final String encryptedKey = keyData['encryptedKey'];

        final groupKeyString = await _cryptoService.decryptWithPrivateKey(encryptedKey);
        final groupKey = enc.Key(base64Decode(groupKeyString));

        _securityService.storeKey(groupId, groupKey);
        AppUtils.log('✅ SUCCESS: Received and decrypted key for group $groupId');

      } catch (e) {
        AppUtils.log('[GroupRepo] Error processing received group key: $e');
      }
    });
  }
}