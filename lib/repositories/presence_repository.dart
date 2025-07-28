import '../services/socket_client.dart';
import '../models/user_model.dart';
import 'dart:async';

class PresenceRepository {
  final SocketClient _socketClient = SocketClient.instance;

  void registerPresence(User user) {
    _socketClient.socket.emitWithAck(
      'register_presence',
      {
        'userId': user.userId,
        'username': user.username,
      },
      ack: (response) {
        // Handle ack if needed
      },
    );
  }

  Future<List<User>> getInitialOnlineUsers() async {
    final completer = Completer<List<User>>();
    print('[PresenceRepository] Requesting initial online users...');
    
    // Add timeout - increased to 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        print('[PresenceRepository] Timeout waiting for online users response');
        completer.complete([]);
      }
    });
    
    _socketClient.socket.emitWithAck('get_initial_online_users', null, ack: (response) {
      print('[PresenceRepository] Received initial online users response: $response');
      if (!completer.isCompleted) {
        if (response is List) {
          final users = response.map((e) => User.fromJson(e)).toList();
          print('[PresenceRepository] Parsed ${users.length} users');
          completer.complete(users);
        } else {
          print('[PresenceRepository] Invalid response format, returning empty list');
          completer.complete([]);
        }
      }
    });
    return completer.future;
  }

  void listenPresenceUpdate(void Function(List<User>) callback) {
    print('[PresenceRepository] Setting up presence update listener...');
    
    // Remove any existing listeners to avoid duplicates
    _socketClient.socket.off('online_users_update');
    
    _socketClient.socket.on('online_users_update', (data) {
      print('[PresenceRepository] Received online users update: $data');
      try {
        List<dynamic> usersData;
        
        // Handle different data formats from backend
        if (data is List) {
          // Check if it's a nested array (backend sometimes sends [[users], reason])
          if (data.isNotEmpty && data[0] is List) {
            usersData = data[0] as List<dynamic>;
            print('[PresenceRepository] Detected nested array format, extracting users from first element');
          } else {
            usersData = data;
          }
          
          final users = usersData.map((e) => User.fromJson(e)).toList();
          print('[PresenceRepository] Parsed ${users.length} users from online users update');
          callback(users);
        } else {
          print('[PresenceRepository] Invalid online users update format: $data');
        }
      } catch (e) {
        print('[PresenceRepository] Error processing presence update: $e');
      }
    });
    
    print('[PresenceRepository] Presence update listener set up successfully');
  }
} 