import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:vibration/vibration.dart'; // Temporarily removed
import '../../models/user_model.dart';
import '../../repositories/presence_repository.dart';
import '../../repositories/call_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/socket_client.dart';
import '../../services/webrtc_service.dart';
import '../../services/permission_service.dart';

class CallViewModel extends ChangeNotifier {
  final PresenceRepository _presenceRepository;
  final CallRepository _callRepository;
  final UserRepository _userRepository;
  final SocketClient _socketClient;

  // State variables
  List<User> _onlineUsers = [];
  List<User> _searchResults = [];
  List<User> _callList = [];
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isIncomingCall = false;
  User? _incomingCallFrom;
  Map<String, dynamic>? _incomingCallPayload;
  bool _isInCall = false;
  bool _isVideoCall = true;
  User? _currentCallPartner;
  String? _callStatusMessage;
  bool _isConnecting = false;
  // WebRTC Service
  WebRTCService? _webrtcService;
  bool _isInitialized = false;
  
  // Incoming call timer and vibration
  Timer? _incomingCallTimer;
  bool _isVibrating = false;

  CallViewModel({
    required PresenceRepository presenceRepository,
    required CallRepository callRepository,
    required UserRepository userRepository,
    required SocketClient socketClient,
  }) : _presenceRepository = presenceRepository,
       _callRepository = callRepository,
       _userRepository = userRepository,
       _socketClient = socketClient;

  // Getters
  List<User> get onlineUsers => _onlineUsers;
  List<User> get searchResults => _searchResults;
  List<User> get callList => _callList;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  bool get isIncomingCall => _isIncomingCall;
  User? get incomingCallFrom => _incomingCallFrom;
  Map<String, dynamic>? get incomingCallPayload => _incomingCallPayload;
  bool get isInCall => _isInCall;
  bool get isVideoCall => _isVideoCall;
  User? get currentCallPartner => _currentCallPartner;
  String? get callStatusMessage => _callStatusMessage;
  bool get isInitialized => _isInitialized;
  WebRTCService? get webrtcService => _webrtcService;
  bool get isConnecting => _isConnecting;

  Future<void> initialize(User currentUser) async {
    try {
      debugPrint('[CallViewModel] Starting initialization...');

      // Connect to socket
      await _socketClient.connectAndListen();
      debugPrint('[CallViewModel] Socket connected');

      // Wait a bit for socket to be fully ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Register presence
      _presenceRepository.registerPresence(currentUser);
      debugPrint('[CallViewModel] Presence registered');

      // Wait a bit more for presence to be processed
      await Future.delayed(const Duration(milliseconds: 500));

      // Get initial online users (only once)
      await _fetchInitialOnlineUsers();

      // Listen for presence updates
      _presenceRepository.listenPresenceUpdate(_onPresenceUpdate);

      // Listen for incoming calls
      debugPrint('[CallViewModel] Setting up incoming call listeners...');
      _callRepository.listenOffer(onIncomingCall);
      _callRepository.listenAnswer(_onAnswer);
      _callRepository.listenCandidate(_onCandidate);
      debugPrint('[CallViewModel] Incoming call listeners set up successfully');

      // Initialize WebRTC service
      _initializeWebRTCService(currentUser);

      _isInitialized = true;
      debugPrint('[CallViewModel] Initialized successfully');
    } catch (e) {
      debugPrint('[CallViewModel] Initialization error: $e');
    }
  }

  // Method to re-initialize for new user (after sign-up)
  Future<void> reinitialize(User currentUser) async {
    try {
      debugPrint('[CallViewModel] Re-initializing for new user: ${currentUser.displayName}');
      
      // Clear existing state
      _onlineUsers.clear();
      _searchResults.clear();
      _callList.clear();
      _searchQuery = '';
      _isSearching = false;
      _isIncomingCall = false;
      _incomingCallFrom = null;
      _incomingCallPayload = null;
      _isInCall = false;
      _currentCallPartner = null;
      _callStatusMessage = null;
      
      // Re-register presence for new user
      _presenceRepository.registerPresence(currentUser);
      debugPrint('[CallViewModel] Presence re-registered for new user');

      // Wait a bit for presence to be processed
      await Future.delayed(const Duration(milliseconds: 500));

      // Get initial online users for new user
      await _fetchInitialOnlineUsers();

      // Re-initialize WebRTC service for new user
      _initializeWebRTCService(currentUser);

      debugPrint('[CallViewModel] Re-initialization completed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('[CallViewModel] Re-initialization error: $e');
    }
  }

  void _initializeWebRTCService(User currentUser) {
    try {
      debugPrint('[CallViewModel] Initializing WebRTC service for user: ${currentUser.userId}');
      
      if (_webrtcService != null) {
        debugPrint('[CallViewModel] Disposing existing WebRTC service');
        _webrtcService!.dispose();
      }

      _webrtcService = WebRTCService(
      myUserId: currentUser.userId.toString(),
      onRemoteStreamReceived: (MediaStream remoteStream) {
        debugPrint('[CallViewModel] Remote stream received');
        notifyListeners();
      },
      onSendOffer: (toUserId, payload) {
        debugPrint('[CallViewModel] Sending offer to $toUserId');
        _callRepository.sendOffer(toUserId: int.parse(toUserId), payload: payload);
      },
      onSendAnswer: (toUserId, payload) {
        debugPrint('[CallViewModel] Sending answer to $toUserId');
        _callRepository.sendAnswer(toUserId: int.parse(toUserId), payload: payload);
      },
      onSendCandidate: (toUserId, payload) {
        debugPrint('[CallViewModel] Sending candidate to $toUserId');
        _callRepository.sendCandidate(toUserId: int.parse(toUserId), payload: payload);
      },
      onCallEstablished: () {
        debugPrint('[CallViewModel] Callback: Call ESTABLISHED.');
        _isInCall = true;
        _isConnecting = false;
        _callStatusMessage = 'Connected';
        notifyListeners();
      },
      onCallFailed: (reason) {
        debugPrint('[CallViewModel] Callback: Call FAILED. Reason: $reason');
        _isInCall = false;
        _isConnecting = false;
        _currentCallPartner = null;
        _callStatusMessage = 'Call Failed';
        notifyListeners();
      },
        onCallEnded: () {
          debugPrint('[CallViewModel] Callback: Call ENDED.');
          _isInCall = false;
          _isConnecting = false;
          _currentCallPartner = null;
          _callStatusMessage = 'Call Ended';
          notifyListeners();
        },
      );
      
      debugPrint('[CallViewModel] WebRTC service initialized successfully');
    } catch (e) {
      debugPrint('[CallViewModel] Error initializing WebRTC service: $e');
      _webrtcService = null;
    }
  }

  Future<void> _fetchInitialOnlineUsers() async {
    try {
      debugPrint('[CallViewModel] Fetching initial online users...');
      final users = await _presenceRepository.getInitialOnlineUsers();
      _onlineUsers = users;
      debugPrint('[CallViewModel] Fetched ${users.length} initial online users: ${users.map((u) => '${u.displayName} (ID: ${u.userId})').join(', ')}');
      notifyListeners();
    } catch (e) {
      debugPrint('[CallViewModel] Error fetching initial online users: $e');
    }
  }

  // Public method to refresh online users (for debugging)
  Future<void> refreshOnlineUsers() async {
    await _fetchInitialOnlineUsers();
  }

  void _onPresenceUpdate(List<User> users) {
    debugPrint('[CallViewModel] Presence update received: ${users.length} users: ${users.map((u) => '${u.displayName} (ID: ${u.userId})').join(', ')}');
    _onlineUsers = users;
    notifyListeners();
  }

  /// Search users by display name
  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;

    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final results = await _userRepository.searchUsers(query);
      // Mark users as online if they are in the onlineUsers list
      _searchResults = results.map((user) {
        // Optionally, you can extend User model to include isOnline
        // For now, just return the user
        return user;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching users: $e');
      _searchResults = [];
      notifyListeners();
    }
  }

  void addUserToCallList(User user) {
    if (!_callList.any((u) => u.userId == user.userId)) {
      _callList.add(user);
      notifyListeners();
    }
  }

  void removeUserFromCallList(User user) {
    _callList.removeWhere((u) => u.userId == user.userId);
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  void onIncomingCall(int fromUserId, Map<String, dynamic> payload) {
    debugPrint('[CallViewModel] 📞 INCOMING CALL from user $fromUserId with payload: $payload');
    
    final caller = _onlineUsers.firstWhere(
      (user) => user.userId == fromUserId,
      orElse: () => User(userId: fromUserId, username: 'Unknown', displayName: 'Unknown User'),
    );

    debugPrint('[CallViewModel] ✅ Caller found: ${caller.displayName}');
    
    _isIncomingCall = true;
    _incomingCallFrom = caller;
    _incomingCallPayload = payload;
    notifyListeners();
    
    debugPrint('[CallViewModel] ✅ Incoming call state set, notifying listeners');
    
    // Start vibration and timer
    _startIncomingCallRinging();
    
    // Show global notification if user is not on call screen
    _showIncomingCallNotification(caller);
  }

  void _startIncomingCallRinging() {
    // Cancel any existing timer
    _incomingCallTimer?.cancel();
    
    // Start vibration pattern
    _startVibration();
    
    // Auto-decline after 30 seconds
    _incomingCallTimer = Timer(const Duration(seconds: 30), () {
      if (_isIncomingCall) {
        debugPrint('[CallViewModel] Incoming call timed out, auto-declining');
        _stopVibration();
        declineIncomingCall();
      }
    });
  }

  void _startVibration() async {
    // Vibration temporarily disabled due to build issues
    // if (await Vibration.hasVibrator() ?? false) {
    //   _isVibrating = true;
    //   // Vibrate pattern: wait 1s, vibrate 1s, wait 1s, vibrate 1s, repeat
    //   Vibration.vibrate(pattern: [1000, 1000, 1000, 1000], repeat: -1);
    // }
  }

  void _stopVibration() {
    // Vibration temporarily disabled due to build issues
    // if (_isVibrating) {
    //   Vibration.cancel();
    //   _isVibrating = false;
    // }
  }

  void _showIncomingCallNotification(User caller) {
    // The incoming call overlay is now handled globally in main.dart
    // This method is kept for potential future use (e.g., push notifications)
    debugPrint('[CallViewModel] Incoming call notification triggered for ${caller.displayName}');
  }

  Future<void> acceptIncomingCall() async {
    // 1. تحقق من أن هناك مكالمة واردة بالفعل لمعالجتها
    if (_incomingCallFrom == null || _incomingCallPayload == null || _webrtcService == null) {
      debugPrint('[CallViewModel] Accept called but no incoming call is present.');
      return;
    }

    debugPrint('[CallViewModel] Accepting incoming call from ${_incomingCallFrom!.displayName}');

    // 2. إيقاف الرنين (الاهتزاز والمؤقت)
    _stopVibration();
    _incomingCallTimer?.cancel();

    // 3. طلب الصلاحيات اللازمة قبل المتابعة
    final permissionService = PermissionService();
    final hasPermissions = await permissionService.requestCallPermissions();

    if (!hasPermissions) {
      debugPrint('[CallViewModel] Call permissions not granted. Declining call.');
      declineIncomingCall(); // ارفض المكالمة إذا لم يتم منح الصلاحيات
      return;
    }

    // 4. تحديث حالة الواجهة فورًا لتعكس أننا نقوم بالاتصال
    //    هذا هو التغيير الرئيسي: نقوم بتحديث الحالة هنا مرة واحدة فقط
    _currentCallPartner = _incomingCallFrom;
    _isInCall = true; // نعتبر أننا "في مكالمة" بمجرد القبول
    _isConnecting = true; // نظهر حالة "جارٍ الاتصال"
    _isIncomingCall = false; // إخفاء واجهة المكالمة الواردة
    _callStatusMessage = 'Connecting...';

    // قم بتنظيف متغيرات المكالمة الواردة
    final partnerToCall = _incomingCallFrom!;
    final payloadToHandle = _incomingCallPayload!;
    _incomingCallFrom = null;
    _incomingCallPayload = null;

    notifyListeners(); // قم بإعلام الواجهة بالتغييرات

    // 5. استدعاء WebRTCService للتعامل مع العرض (Offer)
    //    لا نضع try-catch هنا، لأن onCallFailed سيتعامل مع أي أخطاء
    await _webrtcService!.handleOffer(
      partnerToCall.userId.toString(),
      payloadToHandle,
    );

    // لا تقم بتغيير الحالة هنا. اعتمد على onCallEstablished أو onCallFailed
    // اللذين سيتم استدعاؤهما من WebRTCService لتحديد النتيجة النهائية للاتصال.
  }

  void declineIncomingCall() {
    debugPrint('[CallViewModel] Declining incoming call');
    
    // Stop vibration and timer
    _stopVibration();
    _incomingCallTimer?.cancel();
    
    _isIncomingCall = false;
    _incomingCallFrom = null;
    _incomingCallPayload = null;
    notifyListeners();
  }

  Future<void> initiateCall(User user, {bool isVideo = false}) async {
    if (isInCall) {
      debugPrint('[CallViewModel] Cannot initiate new call while another is active.');
      _callStatusMessage = 'Please end the current call first.';
      notifyListeners();
      return;
    }

    final permissionService = PermissionService();
    final hasPermissions = await permissionService.requestCallPermissions();

    if (!hasPermissions) {
      debugPrint('[CallViewModel] Call permissions denied.');
      _callStatusMessage = 'Camera and microphone permissions are required.';
      notifyListeners();
      return;
    }

    _currentCallPartner = user;
    _isInCall = true;
    _isConnecting = true;
    _isVideoCall = isVideo;
    _callStatusMessage = 'Calling ${user.displayName}...';
    notifyListeners();

    await _webrtcService!.startCall(
      user.userId.toString(),
      isVideoCall: isVideo,
    );

  }

  Future<void> endCall() async {
    debugPrint('[CallViewModel] User initiated endCall.');

    if (_isInCall) {
      _isConnecting = false;
      _callStatusMessage = 'Ending call...';
      notifyListeners();
    }
    await _webrtcService?.hangUp();
  }

  Future<void> toggleAudio() async {
    // TODO: Implement audio toggle
    debugPrint('[CallViewModel] Toggle audio');
  }

  Future<void> toggleVideo() async {
    // TODO: Implement video toggle
    debugPrint('[CallViewModel] Toggle video');
  }

  Future<void> switchCamera() async {
    // TODO: Implement camera switch
    debugPrint('[CallViewModel] Switch camera');
  }

  void _onAnswer(int fromUserId, Map<String, dynamic> payload) {
    debugPrint('[CallViewModel] Received answer from $fromUserId');
    if (_webrtcService != null) {
      _webrtcService!.handleAnswer(fromUserId.toString(), payload);
    }
  }

  void _onCandidate(int fromUserId, Map<String, dynamic> payload) {
    debugPrint('[CallViewModel] Received candidate from $fromUserId');
    if (_webrtcService != null) {
      _webrtcService!.handleCandidate(fromUserId.toString(), payload);
    }
  }

  /// Resets the entire state of the ViewModel to its initial values.
  /// This should be called on user logout.
  void reset() {
    _onlineUsers = [];
    _searchResults = [];
    _callList = [];
    _searchQuery = '';
    _isSearching = false;
    _isIncomingCall = false;
    _incomingCallFrom = null;
    _incomingCallPayload = null;
    _isInCall = false;
    _currentCallPartner = null;
    _callStatusMessage = null;
    _isInitialized = false;

    _webrtcService?.dispose();
    _webrtcService = null;

    _incomingCallTimer?.cancel();
    _incomingCallTimer = null;

    _stopVibration();

    if (kDebugMode) {
      print('[CallViewModel] State has been reset.');
    }


    notifyListeners();
  }

  @override
  void dispose() {
    _stopVibration();
    _incomingCallTimer?.cancel();
    _webrtcService?.dispose();
    super.dispose();
  }
} 