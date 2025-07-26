// lib/view_models/chat/chat_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart'; // Assuming you'll need the user's info
import '../../repositories/messaging_repository.dart';
import '../../shared/enums.dart';
import '../../shared/failure.dart';
import '../../shared/utils.dart';
import '../../services/socket_client.dart';


class ChatViewModel extends ChangeNotifier {
  final MessagingRepository _messagingRepository = MessagingRepository();
  final _socket = SocketClient.instance.socket;
  final _uuid = const Uuid();

  final int chatId;
  final User currentUser;

  ChatViewModel({required this.chatId, required this.currentUser}) {
    _listenForNewMessages();
  }

  ViewState _state = ViewState.Idle;
  ViewState get state => _state;

  Failure? _failure;
  Failure? get failure => _failure;

  List<Message> _messages = [];
  List<Message> get messages => _messages;

  void _setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void _setFailure(Failure failure) {
    _failure = failure;
    _setState(ViewState.Error);
  }

  Future<void> fetchInitialMessages() async {
    // ... (code from previous steps)
  }

  /// Handles sending a message with optimistic UI updates.
  void sendMessage(String text) {
    final clientMessageId = _uuid.v4();

    // 1. Create a temporary message and add it to the UI immediately.
    final tempMessage = Message(
      groupId: chatId,
      senderId: currentUser.userId,
      senderUsername: currentUser.username,
      textMessage: text,
      clientMessageId: clientMessageId,
      status: MessageStatus.sending, // The UI will show the sending icon
      sentAt: DateTime.now(),
    );
    _messages.insert(0, tempMessage);
    notifyListeners();

    // 2. Try to send the message to the server.
    try {
      _messagingRepository.sendMessage(
        chatId,
        text,
        clientMessageId,
      );
      // We don't await. We just fire it and assume it will get there.
      // The 'newMessage' event will be our confirmation.
    } catch (e) {
      // 3. If the emit fails immediately (e.g., socket is disconnected),
      // update the message status to 'failed'.
      _updateMessageStatus(clientMessageId, MessageStatus.failed);
      _setFailure(ServerFailure(e.toString()));
    }
  }

  void _listenForNewMessages() {
    _socket.on('newMessage', _handleNewMessage);
  }

  void _handleNewMessage(dynamic data) {
    AppUtils.log('[ViewModel] Received newMessage event with data: $data');

    try {
      // Fix: handle if data is a List and extract the first element
      final messageData = (data is List && data.isNotEmpty) ? data[0] : data;
      final message = Message.fromJson(messageData as Map<String, dynamic>);
      AppUtils.log('[ViewModel] Parsed message successfully: ${message.textMessage}');

      // Try to find an optimistic message with the same clientMessageId
      final optimisticIndex = _messages.indexWhere(
        (m) => m.clientMessageId == message.clientMessageId && m.status == MessageStatus.sending,
      );
      if (optimisticIndex != -1) {
        // Replace the optimistic message with the confirmed one
        _messages[optimisticIndex] = message.copyWith(newStatus: MessageStatus.sent);
        notifyListeners();
        return;
      }

      // Otherwise, add as a new message if not already present
      if (!_messages.any((m) => m.messageId == message.messageId)) {
        _messages.insert(0, message);
        notifyListeners();
      }
    } catch (e) {
      AppUtils.log("[ViewModel] Error parsing new message: $e");
    }
  }




  void _updateMessageStatus(String clientMsgId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.clientMessageId == clientMsgId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(newStatus: status);
      notifyListeners();
    }
  }

  /// Retry sending a failed message
  void retryMessage(Message message) {
    if (message.status != MessageStatus.failed) return;
    
    // Update status to sending
    _updateMessageStatus(message.clientMessageId, MessageStatus.sending);
    
    try {
      _messagingRepository.sendMessage(
        message.groupId,
        message.textMessage,
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