import '../services/socket_client.dart';

class CallRepository {
  final SocketClient _socketClient = SocketClient.instance;

  void sendOffer({required int toUserId, required Map<String, dynamic> payload}) {
    print('[CallRepository] 📤 Sending offer to user $toUserId: $payload');
    _socketClient.socket.emit('offer', {'toUserId': toUserId, 'payload': payload});
  }

  void sendAnswer({required int toUserId, required Map<String, dynamic> payload}) {
    _socketClient.socket.emit('answer', {'toUserId': toUserId, 'payload': payload});
  }

  void sendCandidate({required int toUserId, required Map<String, dynamic> payload}) {
    _socketClient.socket.emit('candidate', {'toUserId': toUserId, 'payload': payload});
  }

  void listenOffer(void Function(int fromUserId, Map<String, dynamic> payload) callback) {
    print('[CallRepository] Setting up offer listener...');
    
    // Remove any existing listeners to avoid duplicates
    _socketClient.socket.off('getOffer');
    
    _socketClient.socket.on('getOffer', (data) {
      print('[CallRepository] 🎯 RECEIVED getOffer event: $data');
      
      Map<String, dynamic>? offerData;
      
      // Handle different data formats from backend
      if (data is Map) {
        offerData = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty && data[0] is Map) {
        // Backend sometimes sends array format: [{fromUserId: X, payload: Y}]
        offerData = Map<String, dynamic>.from(data[0]);
        print('[CallRepository] Detected array format, extracting first element');
      }
      
      if (offerData != null && offerData['fromUserId'] != null && offerData['payload'] != null) {
        final fromUserId = offerData['fromUserId'];
        final payload = Map<String, dynamic>.from(offerData['payload']);
        print('[CallRepository] ✅ Processing offer from user $fromUserId with payload: $payload');
        callback(fromUserId, payload);
      } else {
        print('[CallRepository] ❌ Invalid getOffer data format: $data');
      }
    });
    
    print('[CallRepository] ✅ Offer listener set up successfully');
  }

  void listenAnswer(void Function(int fromUserId, Map<String, dynamic> payload) callback) {
    _socketClient.socket.on('getAnswer', (data) {
      Map<String, dynamic>? answerData;
      
      if (data is Map) {
        answerData = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty && data[0] is Map) {
        answerData = Map<String, dynamic>.from(data[0]);
      }
      
      if (answerData != null && answerData['fromUserId'] != null && answerData['payload'] != null) {
        callback(answerData['fromUserId'], Map<String, dynamic>.from(answerData['payload']));
      }
    });
  }

  void listenCandidate(void Function(int fromUserId, Map<String, dynamic> payload) callback) {
    _socketClient.socket.on('getCandidate', (data) {
      Map<String, dynamic>? candidateData;
      
      if (data is Map) {
        candidateData = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty && data[0] is Map) {
        candidateData = Map<String, dynamic>.from(data[0]);
      }
      
      if (candidateData != null && candidateData['fromUserId'] != null && candidateData['payload'] != null) {
        callback(candidateData['fromUserId'], Map<String, dynamic>.from(candidateData['payload']));
      }
    });
  }
} 