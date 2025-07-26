// lib/core/socket_client.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // Required for kDebugMode
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'secure_storage_service.dart';
import '../core/config.dart';
import '../models/user_model.dart';
class SocketClient {
  SocketClient._privateConstructor();
  static final SocketClient instance = SocketClient._privateConstructor();

  io.Socket? _socket;
  Timer? _heartbeatTimer;
  bool _isHeartbeatActive = false;
  
  io.Socket get socket {
    if (_socket == null) {
      throw Exception("Socket not initialized. Call connectAndListen() first.");
    }
    return _socket!;
  }

  Future<void> connectAndListen() async {
    if (_socket != null && _socket!.connected) {
      if (kDebugMode) print("[Socket] Already connected.");
      return;
    }

    final token = await SecureStorageService.instance.getToken();

    _socket = io.io(AppConfig.instance.baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableReconnection()
            .build()
    );

    _socket!.onConnect((_) {
      if (kDebugMode) print('[Socket] Connected: ${_socket!.id}');
      _startHeartbeat();
    });

    _socket!.onDisconnect((reason) {
      if (kDebugMode) print('[Socket] Disconnected: $reason');
      _stopHeartbeat();
    });

    _socket!.onConnectError((data) {
      if (kDebugMode) print('[Socket] Connect Error: $data');
      _stopHeartbeat();
    });

    _socket!.onError((data) {
      if (kDebugMode) print('[Socket] Error: $data');
      _stopHeartbeat();
    });

    // Listen for heartbeat acknowledgments from server
    _socket!.on('heartbeat_ack', (data) {
      if (kDebugMode) print('[Socket] Heartbeat acknowledged by server');
    });
  }

  void registerPresence(User user) {
    if (_socket == null || !_socket!.connected) {
      if (kDebugMode) print('[Socket] Cannot register presence, socket not connected.');
      return;
    }

    // CORRECTED: Use emitWithAck for acknowledgements
    _socket!.emitWithAck(
        'register_presence', // 1st argument: event name
        {                   // 2nd argument: data
          'userId': user.userId,
          'username': user.username,
        },
        ack: (response) {     // 3rd argument: the 'ack' named parameter
          if (kDebugMode) {
            if (response is Map && response['success'] == true) {
              print('[Socket] Presence registered successfully.');
            } else {
              print('[Socket] Presence registration failed: $response');
            }
          }
        }
    );
  }

  void _startHeartbeat() {
    // Cancel any existing timer to be safe
    _stopHeartbeat();

    // Only start heartbeat if socket is connected
    if (_socket == null || !_socket!.connected) {
      if (kDebugMode) print('[Socket] Cannot start heartbeat: socket not connected');
      return;
    }

    _isHeartbeatActive = true;
    
    // Send a heartbeat every 10 seconds. The server timeout is typically 30-60 seconds,
    // so this gives us plenty of buffer while being less aggressive.
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _sendHeartbeat();
    });
    
    if (kDebugMode) print('[Socket] Heartbeat started');
  }

  void _sendHeartbeat() {
    // Check if socket is still connected and heartbeat is active
    if (_socket == null || !_socket!.connected || !_isHeartbeatActive) {
      if (kDebugMode) print('[Socket] Cannot send heartbeat: socket disconnected or heartbeat stopped');
      _stopHeartbeat();
      return;
    }

    try {
      _socket!.emit('heartbeat');
      if (kDebugMode) print('[Socket] Sent heartbeat');
    } catch (e) {
      if (kDebugMode) print('[Socket] Failed to send heartbeat: $e');
      _stopHeartbeat();
    }
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isHeartbeatActive = false;
    if (kDebugMode) print('[Socket] Heartbeat stopped');
  }

  void disconnect() {
    _stopHeartbeat();
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    if (kDebugMode) print('[Socket] Explicitly disconnected');
  }

  /// Check if the socket is currently connected
  bool get isConnected => _socket != null && _socket!.connected;

  /// Check if heartbeat is currently active
  bool get isHeartbeatActive => _isHeartbeatActive;

  /// Manually restart heartbeat (useful for debugging or recovery)
  void restartHeartbeat() {
    if (isConnected) {
      _startHeartbeat();
    } else {
      if (kDebugMode) print('[Socket] Cannot restart heartbeat: socket not connected');
    }
  }
}