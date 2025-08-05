// lib/view_models/chat/chat_viewmodel.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../repositories/messaging_repository.dart';
import '../../services/locator.dart';
import '../../services/socket_client.dart';
import '../../services/crypto_service.dart';
import '../../services/chat_security_service.dart';
import '../../shared/enums.dart';
import '../../shared/failure.dart';
import '../../shared/utils.dart';
import '../../shared/exceptions.dart';

class ChatViewModel extends ChangeNotifier {
  // Dependencies
  final MessagingRepository _messagingRepository = sl<MessagingRepository>();
  final CryptoService _cryptoService = sl<CryptoService>();
  final ChatSecurityService _securityService = sl<ChatSecurityService>();
  final _socket = sl<SocketClient>().socket;
  final _uuid = const Uuid();

  // Properties
  final int chatId;
  final User currentUser;
  enc.Key? _groupKey;

  // State properties
  ViewState _state = ViewState.Idle;
  ViewState get state => _state;
  Failure? _failure;
  Failure? get failure => _failure;
  List<Message> _messages = [];
  List<Message> get messages => _messages;

  ChatViewModel({required this.chatId, required this.currentUser}) {
    _initialize();
  }

  void _setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _failure = failure;
    _setState(ViewState.Error);
  }

  Future<void> _initialize() async {
    _setState(ViewState.Busy);

    // Step 1: Check the local cache first.
    _groupKey = _securityService.getKey(chatId.toString());

    // Step 2: If the key is NOT in the cache, fetch it from the server.
    if (_groupKey == null) {
      AppUtils.log("[ChatVM] Key not in cache for group $chatId. Fetching from server...");
      try {
        // 2a. Call the new repository method.
        final encryptedKey = await _messagingRepository.getMyEncryptedKey(chatId);

        if (encryptedKey != null) {
          // 2b. If we got the key, decrypt it.
          final groupKeyString = await _cryptoService.decryptWithPrivateKey(encryptedKey);
          final groupKey = enc.Key(base64Decode(groupKeyString));

          // 2c. Store the newly decrypted key in the cache for next time.
          _securityService.storeKey(chatId.toString(), groupKey);
          _groupKey = groupKey; // Assign it to our local variable
          AppUtils.log("[ChatVM] Successfully fetched and decrypted key for group $chatId.");
        }
      } catch (e) {
        AppUtils.log("[ChatVM] ❌ FAILED to fetch/decrypt key: $e");
        _setFailure(ServerFailure("Could not retrieve security key for this chat."));
        return;
      }
    }

    // Step 3: If after all that, the key is STILL null, then we have a problem.
    if (_groupKey == null) {
      _setFailure(ServerFailure("Security Error: Group key is missing and could not be recovered."));
      return;
    }

    // Step 4: Proceed with loading messages now that we are sure we have the key.
    _listenForNewMessages();
    await fetchInitialMessages();
  }

  Future<void> fetchInitialMessages() async {
    if (_groupKey == null) {
      _setFailure(ServerFailure("Cannot fetch messages: group key is missing."));
      _setState(ViewState.Error); // Ensure UI stops loading
      return;
    };

    _setState(ViewState.Busy);
    try {
      final messagesFromDb = await _messagingRepository.getMessagesForChat(chatId);
      final decryptedMessages = <Message>[];

      for (var msg in messagesFromDb) {
        final decryptedText = _cryptoService.decryptSymmetric(msg.textMessage, _groupKey!);
        decryptedMessages.add(msg.copyWith(textMessage: decryptedText));
      }

      _messages = decryptedMessages;
      _setState(ViewState.Idle);

    } on AppException catch (e) {
      _setFailure(ServerFailure(e.message));
    }
  }

  void sendMessage(String text) {
    if (_groupKey == null) {
      _setFailure(ServerFailure("Cannot send message: Security key missing."));
      return;
    }

    final clientMessageId = _uuid.v4();

    final tempMessage = Message(
      groupId: chatId,
      senderId: currentUser.userId,
      senderUsername: currentUser.username,
      textMessage: text,
      clientMessageId: clientMessageId,
      status: MessageStatus.sending,
      sentAt: DateTime.now(),
    );
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // 1. Encrypt the message text
      final encryptedPayload = _cryptoService.encryptSymmetric(text, _groupKey!);

      // 2. Send the ENCRYPTED payload using the OLD repository method
      _messagingRepository.sendMessage(
        chatId,
        encryptedPayload, // Pass the encrypted payload as the 'text'
        clientMessageId,
      );
    } catch (e) {
      _updateMessageStatus(clientMessageId, MessageStatus.failed);
      _setFailure(ServerFailure(e.toString()));
    }
  }

  void _listenForNewMessages() {
    _socket.off('newMessage'); // Ensure we remove any old listeners to prevent duplicates
    _socket.on('newMessage', _handleNewMessage);
  }

  void _handleNewMessage(dynamic data) {
    if (_groupKey == null) return;

    try {
      final messageData = (data is List && data.isNotEmpty) ? data[0] : data;
      final message = Message.fromJson(messageData as Map<String, dynamic>);

      // Decrypt the incoming message's text
      final decryptedText = _cryptoService.decryptSymmetric(message.textMessage, _groupKey!);
      final decryptedMessage = message.copyWith(textMessage: decryptedText);

      final optimisticIndex = _messages.indexWhere(
            (m) => m.clientMessageId == decryptedMessage.clientMessageId && m.status == MessageStatus.sending,
      );

      if (optimisticIndex != -1) {
        // This is our own message coming back from the server, so we replace the temp one.
        _messages[optimisticIndex] = decryptedMessage.copyWith(newStatus: MessageStatus.sent);
      } else {
        // This is a new message from someone else, so we add it to the top.
        if (!_messages.any((m) => m.messageId == decryptedMessage.messageId && decryptedMessage.messageId != 0)) {
          _messages.insert(0, decryptedMessage);
        }
      }
      notifyListeners();

    } catch (e) {
      AppUtils.log("[ViewModel] Error parsing or decrypting new message: $e");
    }
  }

  void _updateMessageStatus(String clientMsgId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.clientMessageId == clientMsgId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(newStatus: status);
      notifyListeners();
    }
  }

  void retryMessage(Message message) {
    if (message.status != MessageStatus.failed) return;

    _updateMessageStatus(message.clientMessageId, MessageStatus.sending);

    try {
      if (_groupKey == null) throw Exception("Security key is missing for retry.");

      // Encrypt the text again before retrying
      final encryptedPayload = _cryptoService.encryptSymmetric(message.textMessage, _groupKey!);

      _messagingRepository.sendMessage(
        message.groupId,
        encryptedPayload,
        message.clientMessageId,
      );
    } catch (e) {
      _updateMessageStatus(message.clientMessageId, MessageStatus.failed);
      _setFailure(ServerFailure('Failed to retry message: $e'));
    }
  }

  @override
  void dispose() {
    _socket.off('newMessage', _handleNewMessage);
    super.dispose();
  }
}