import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallConnectionState {
  Idle,
  Connecting,
  Connected,
  Disconnected,
  Failed,
  Closed,
}

class WebRTCService {
  final String myUserId;
  final Function(MediaStream remoteStream) onRemoteStreamReceived;
  final VoidCallback? onCallEstablished;
  final Function(String reason)? onCallFailed;
  final VoidCallback? onCallEnded;
  final Function(String toUserId, Map<String, dynamic> payload) onSendOffer;
  final Function(String toUserId, Map<String, dynamic> payload) onSendAnswer;
  final Function(String toUserId, Map<String, dynamic> payload) onSendCandidate;

  String? _currentTargetUserId;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isVideoCall = true;
  CallConnectionState _connectionState = CallConnectionState.Idle;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCVideoRenderer get localVideoRenderer => localRenderer;
  RTCVideoRenderer get remoteVideoRenderer => remoteRenderer;
  bool get isCallActive => _connectionState == CallConnectionState.Connected || _connectionState == CallConnectionState.Connecting;
  String? get currentTargetUserId => _currentTargetUserId;

  WebRTCService({
    required this.myUserId,
    required this.onRemoteStreamReceived,
    required this.onSendOffer,
    required this.onSendAnswer,
    required this.onSendCandidate,
    this.onCallEstablished,
    this.onCallFailed,
    this.onCallEnded,
  }) {
    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      debugPrint('WebRTCService ($myUserId): Renderers initialized.');
    } catch (e) {
      debugPrint('WebRTCService ($myUserId): Error initializing renderers: $e');
    }
  }

  Future<void> _cleanup() async {
    debugPrint("WebRTCService ($myUserId): Starting cleanup for user ${_currentTargetUserId ?? 'N/A'}.");
    _connectionState = CallConnectionState.Closed;

    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
        debugPrint("WebRTCService ($myUserId): Local stream tracks stopped and stream disposed.");
      }

      if (localRenderer.srcObject != null) localRenderer.srcObject = null;
      if (remoteRenderer.srcObject != null) remoteRenderer.srcObject = null;
      debugPrint("WebRTCService ($myUserId): Renderers cleared.");

      await _peerConnection?.close();
      _peerConnection = null;
      debugPrint("WebRTCService ($myUserId): PeerConnection closed.");

    } catch (e) {
      debugPrint("WebRTCService ($myUserId): Error during cleanup: $e");
    } finally {
      _currentTargetUserId = null;
    }
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) {
      await _cleanup();
    }

    final config = {'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]};

    try {
      _peerConnection = await createPeerConnection(config);
      _connectionState = CallConnectionState.Connecting;
      debugPrint("WebRTCService ($myUserId): PeerConnection CREATED.");

      _peerConnection!.onIceCandidate = _onIceCandidate;
      _peerConnection!.onTrack = _onTrack;
      _peerConnection!.onConnectionState = _onConnectionStateChanged;

    } catch (e) {
      debugPrint('Error creating PeerConnection: $e');
      _connectionState = CallConnectionState.Failed;
      onCallFailed?.call("Failed to create peer connection.");
    }
  }

  Future<void> _initializeLocalStream() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': _isVideoCall ? {'facingMode': 'user'} : false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;

      _localStream!.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });
      debugPrint('WebRTCService ($myUserId): Local stream obtained and tracks added.');
    } catch (e) {
      debugPrint('Error getting user media: $e');
      _connectionState = CallConnectionState.Failed;
      onCallFailed?.call("Could not access camera/microphone.");
      await _cleanup();
    }
  }

  void _onIceCandidate(RTCIceCandidate candidate) {
    if (_currentTargetUserId != null) {
      onSendCandidate(_currentTargetUserId!, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    }
  }

  void _onTrack(RTCTrackEvent event) {
    if (event.streams.isNotEmpty) {
      remoteRenderer.srcObject = event.streams[0];
      onRemoteStreamReceived(event.streams[0]);
      debugPrint("WebRTCService ($myUserId): Remote track received.");
    }
  }

  void _onConnectionStateChanged(RTCPeerConnectionState state) {
    debugPrint("WebRTCService ($myUserId): Peer Connection State CHANGED to: $state");
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _connectionState = CallConnectionState.Connected;
        onCallEstablished?.call();
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _connectionState = CallConnectionState.Failed;
        onCallFailed?.call("Connection failed.");
        _cleanup();
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        if (_connectionState != CallConnectionState.Closed) {
          onCallEnded?.call();
          _cleanup();
        }
        break;
      default:
        break;
    }
  }

  // --- Public Methods ---

  Future<void> startCall(String targetUserId, {required bool isVideoCall}) async {
    if (isCallActive) {
      debugPrint("WebRTCService ($myUserId): Already in a call. Please hang up first.");
      return;
    }

    _currentTargetUserId = targetUserId;
    _isVideoCall = isVideoCall;

    await _createPeerConnection();
    await _initializeLocalStream();

    if (_peerConnection == null) return;

    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      onSendOffer(_currentTargetUserId!, {
        'sdp': offer.sdp,
        'type': offer.type,
        'callType': _isVideoCall ? 'video' : 'audio'
      });
      debugPrint('WebRTCService ($myUserId): Sent offer to $_currentTargetUserId');
    } catch (e) {
      debugPrint('Error creating offer: $e');
      onCallFailed?.call("Error initiating call.");
      await _cleanup();
    }
  }

  Future<void> handleOffer(String fromUserId, Map<String, dynamic> sdpData) async {
    if (isCallActive) {
      debugPrint("WebRTCService ($myUserId): Ignoring offer while already in a call.");
      return;
    }

    _currentTargetUserId = fromUserId;
    _isVideoCall = (sdpData['callType'] as String? ?? 'video') == 'video';

    await _createPeerConnection();
    await _initializeLocalStream();

    if (_peerConnection == null) return;

    try {
      await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdpData['sdp'], sdpData['type']));
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      onSendAnswer(_currentTargetUserId!, {'sdp': answer.sdp, 'type': answer.type});
      debugPrint('WebRTCService ($myUserId): Sent answer to $_currentTargetUserId');
    } catch (e) {
      debugPrint('Error handling offer: $e');
      onCallFailed?.call("Error handling offer.");
      await _cleanup();
    }
  }

  Future<void> handleAnswer(String fromUserId, Map<String, dynamic> sdpData) async {
    if (_peerConnection != null && _currentTargetUserId == fromUserId) {
      try {
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdpData['sdp'], sdpData['type']));
        debugPrint('WebRTCService ($myUserId): Set remote description from answer successfully.');
      } catch (e) {
        debugPrint('Error handling answer: $e');
        onCallFailed?.call("Error processing answer.");
        await _cleanup();
      }
    }
  }

  Future<void> handleCandidate(String fromUserId, Map<String, dynamic> candidateData) async {
    if (_peerConnection != null && _currentTargetUserId == fromUserId) {
      try {
        final candidate = RTCIceCandidate(
            candidateData['candidate'],
            candidateData['sdpMid'],
            (candidateData['sdpMLineIndex'] as num?)?.toInt()
        );
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('Error adding ICE candidate: $e');
      }
    }
  }

  Future<void> hangUp() async {
    await _cleanup();
    onCallEnded?.call();
  }

  Future<void> dispose() async {
    debugPrint("WebRTCService ($myUserId): DISPOSING WebRTCService instance...");
    await _cleanup();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    debugPrint("WebRTCService ($myUserId): WebRTCService instance disposed.");
  }
}