// lib/repositories/messaging_repository.dart

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';
import '../services/dio_client.dart';
import '../services/socket_client.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import '../shared/exceptions.dart';
import '../services/locator.dart';

class MessagingRepository {
  final Dio _dio = sl<DioClient>().dio;
  
  // Get socket lazily when needed, not during initialization
  io.Socket get _socket => sl<SocketClient>().socket;

  /// Fetches the list of chats for the user.
  Future<List<Group>> getMyChats() async {
    // ... (code from previous steps)
    try {
      final response = await _dio.get(ApiEndPoints.chats);
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> chatData = response.data;
        return chatData.map((json) => Group.fromJson(json)).toList();
      } else {
        throw ServerException('Failed to load chats: Invalid response format.');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException('Please check your internet connection.');
      }
      throw ServerException(e.response?.data['error'] ?? 'Failed to load chats.');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  /// Fetches the message history for a specific chat.
  Future<List<Message>> getMessagesForChat(int chatId) async {
    try {
      print("--- [Repo] Fetching messages for chatId: $chatId ---");
      final response = await _dio.get(ApiEndPoints.chatMessages(chatId));

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> messageData = response.data;
        // The .map() function iterates over the list and converts each JSON object
        // into a Message model using our fromJson factory.
        final messages = messageData.map((json) => Message.fromJson(json)).toList();
        print("--- [Repo] Successfully fetched and parsed ${messages.length} messages ---");
        return messages;
      } else {
        throw ServerException('Failed to load messages: Invalid response format.');
      }
    } on DioException catch (e) {
      // You can add more specific error handling here if needed
      throw ServerException(e.response?.data['error'] ?? 'Failed to load messages.');
    } catch (e) {
      throw ServerException('An unexpected error occurred while fetching messages: $e');
    }
  }

  /// Sends a new message via Socket.IO and returns the confirmed message from the server.
  void sendMessage(int chatId, String text, String clientMessageId) {
    try {
      if (!_socket.connected) {
        // If the socket isn't even connected, we can fail early.
        throw NetworkException('Cannot send message: Not connected to server.');
      }

      _socket.emit('sendMessage', {
        'chatId': chatId,
        'text': text,
        'clientMessageId': clientMessageId,
      });
      // Note: We don't use emitWithAck and we don't return a Future.
    } catch (e) {
      // Catch potential errors if the socket is in a bad state.
      throw NetworkException('Failed to emit message. Please check your connection.');
    }
  }

  Future<String?> getMyEncryptedKey(int chatId) async {
    try {
      // This endpoint needs to be defined in your ApiEndPoints constants
      final response = await _dio.get('/api/chats/$chatId/my-key');
      if (response.statusCode == 200 && response.data['encryptedGroupKey'] != null) {
        return response.data['encryptedGroupKey'] as String;
      }
      return null;
    } on DioException {
      // Return null if not found or if there's an error
      return null;
    }
  }
}