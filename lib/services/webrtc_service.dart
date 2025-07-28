import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  final String myUserId;
  String? targetUserIdForCall;
  final Function(MediaStream remoteStream) onRemoteStreamReceived;
  final VoidCallback? onCallEstablished;
  final Function(String reason)? onCallFailed;
  final VoidCallback? onCallEnded;
  final Function(String toUserId, Map<String, dynamic> payload) onSendOffer;
  final Function(String toUserId, Map<String, dynamic> payload) onSendAnswer;
  final Function(String toUserId, Map<String, dynamic> payload) onSendCandidate;

  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _internalCallIsActive = false;
  bool isVideoCall = true;

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
    _initializeWebRTCRenderers();
  }

  Future<void> _initializeWebRTCRenderers() async {
    try {
      if (!localRenderer.renderVideo) await localRenderer.initialize();
      if (!remoteRenderer.renderVideo) await remoteRenderer.initialize();
      debugPrint('WebRTCService ($myUserId): Renderers initialized.');
    } catch (e) {
      debugPrint('WebRTCService ($myUserId): Error initializing renderers: $e');
    }
  }

  Future<void> _disposePeerConnectionResources() async {
    if (_peerConnection != null) {
      debugPrint("WebRTCService ($myUserId): Disposing existing PeerConnection (ID: ${_peerConnection?.hashCode}).");
      try {
        final senders = await _peerConnection?.getSenders();
        senders?.forEach((sender) {
          _peerConnection?.removeTrack(sender);
        });
      } catch (e) {
        debugPrint("Error removing tracks: $e");
      }
      await _peerConnection!.close();
      _peerConnection = null;
    }
    if (remoteRenderer.srcObject != null) {
      remoteRenderer.srcObject = null;
      debugPrint("WebRTCService ($myUserId): Remote renderer srcObject cleared.");
    }
  }

  Future<void> _createPeerConnection({required bool offerVideo}) async {
    await _disposePeerConnectionResources();

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };
    final Map<String, dynamic> sdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': offerVideo,
      },
      'optional': [],
    };

    try {
      _peerConnection = await createPeerConnection(config, sdpConstraints);
      debugPrint("WebRTCService ($myUserId): PeerConnection CREATED (ID: ${_peerConnection?.hashCode}). OfferVideo: $offerVideo");

      _peerConnection!.onIceCandidate = (candidate) {
        if (targetUserIdForCall != null && targetUserIdForCall!.isNotEmpty) {
          onSendCandidate(targetUserIdForCall!, {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
        }
      };

      _peerConnection!.onTrack = (event) {
        debugPrint("WebRTCService ($myUserId): Remote track received, streams: ${event.streams.length}, kind: ${event.track.kind}");
        if (event.streams.isNotEmpty) {
          if (isVideoCall || event.track.kind == 'audio') {
            remoteRenderer.srcObject = event.streams[0];
            onRemoteStreamReceived(event.streams[0]);
          } else if (!isVideoCall && event.track.kind == 'video') {
            debugPrint("WebRTCService ($myUserId): Received video track on audio-only call. Ignoring for remote renderer.");
          }
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint("WebRTCService ($myUserId): Peer Connection State CHANGED to: $state (Target: ${targetUserIdForCall ?? 'N/A'}, PC: ${_peerConnection?.hashCode})");
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _internalCallIsActive = true;
            onCallEstablished?.call();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            debugPrint("WebRTCService ($myUserId): Peer connection with ${targetUserIdForCall ?? 'N/A'} is ${state.name}. Hanging up if call was active or PC exists.");
            if (_internalCallIsActive || _peerConnection != null) {
              onCallFailed?.call("Peer connection state: ${state.name}");
              hangUp();
            }
            break;
          default:
            break;
        }
      };

      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          if (track.kind == 'audio' || (isVideoCall && track.kind == 'video')) {
            _peerConnection?.addTrack(track, _localStream!);
          }
        });
      }
    } catch (e, s) {
      debugPrint('Error creating PeerConnection for $myUserId: $e\nStack: $s');
      onCallFailed?.call("Error creating peer connection: ${e.toString()}");
    }
  }

  Future<void> _initializeLocalStreamAndTracks({required bool videoIsEnabled}) async {
    bool reinitializeStream = false;
    if (_localStream != null) {
      bool currentStreamHasVideo = _localStream!.getVideoTracks().isNotEmpty;
      if (videoIsEnabled && !currentStreamHasVideo) reinitializeStream = true;
      if (!videoIsEnabled && currentStreamHasVideo) reinitializeStream = true;

      if (reinitializeStream) {
        debugPrint("WebRTCService ($myUserId): Video constraint changed (current video: $currentStreamHasVideo, requested video: $videoIsEnabled). Re-initializing local stream.");
        await _localStream!.dispose();
        _localStream = null;
        if (localRenderer.srcObject != null) localRenderer.srcObject = null;
      } else {
        debugPrint("WebRTCService ($myUserId): Local stream already exists with appropriate tracks for videoEnabled: $videoIsEnabled.");
        if (_peerConnection != null) {
          _localStream!.getTracks().forEach((track) {
            if (track.kind == 'audio' || (videoIsEnabled && track.kind == 'video')) {
              _peerConnection!.addTrack(track, _localStream!);
            }
          });
        }
        return;
      }
    }

    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': videoIsEnabled ? {'facingMode': 'user'} : false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      if (videoIsEnabled && _localStream!.getVideoTracks().isNotEmpty) {
        localRenderer.srcObject = _localStream;
      } else if (!videoIsEnabled) {
        localRenderer.srcObject = null;
      }
      debugPrint('WebRTCService ($myUserId): Local stream obtained. Video tracks: ${_localStream!.getVideoTracks().length}');

      _localStream!.getTracks().forEach((track) {
        if (track.kind == 'audio' || (videoIsEnabled && track.kind == 'video')) {
          _peerConnection?.addTrack(track, _localStream!);
        }
      });
    } catch (e, s) {
      debugPrint('Error in _initializeLocalStreamAndTracks for $myUserId: $e\nStack: $s');
      onCallFailed?.call("Could not access camera/microphone: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> startCall(String targetUserId, {required bool isVideoCall}) async {
    this.isVideoCall = isVideoCall;
    
    if (targetUserId.isEmpty) {
      onCallFailed?.call("Target user ID cannot be empty");
      return;
    }

    if (_internalCallIsActive && this.targetUserIdForCall == targetUserId && _peerConnection != null && this.isVideoCall == isVideoCall) {
      debugPrint("WebRTCService ($myUserId): Already in a similar call with $targetUserId.");
      return;
    }
    if (_internalCallIsActive && this.targetUserIdForCall != null) {
      debugPrint("WebRTCService ($myUserId): An old call exists or call type changed. Hanging up before new call.");
      await hangUp();
    }

    this.targetUserIdForCall = targetUserId;
    _internalCallIsActive = false;
    debugPrint("WebRTCService ($myUserId): Attempting to start ${isVideoCall ? 'VIDEO' : 'AUDIO'} call to $targetUserIdForCall");

    await _createPeerConnection(offerVideo: isVideoCall);

    try {
      await _initializeLocalStreamAndTracks(videoIsEnabled: isVideoCall);

      if (_peerConnection == null || _localStream == null) {
        debugPrint("WebRTCService ($myUserId): PC or LocalStream null before createOffer. Aborting.");
        onCallFailed?.call("Internal error starting call (PC/Stream null).");
        return;
      }

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      onSendOffer(targetUserIdForCall!, {
        'sdp': offer.sdp,
        'type': offer.type,
        'callType': isVideoCall ? 'video' : 'audio'
      });
      _internalCallIsActive = true;
      debugPrint('WebRTCService ($myUserId): Sent ${isVideoCall ? 'VIDEO' : 'AUDIO'} offer to $targetUserIdForCall');
    } catch (e, s) {
      _internalCallIsActive = false;
      debugPrint('Error in startCall for $myUserId: $e\nStack: $s');
      onCallFailed?.call("Error initiating call: ${e.toString()}");
    }
  }

  Future<void> handleOffer(String fromUserId, Map<String, dynamic> sdpData) async {
    final String incomingCallType = sdpData['callType'] as String? ?? 'video';
    this.isVideoCall = (incomingCallType == 'video');
    debugPrint('>>>>> WebRTCService ($myUserId): ENTERED handleOffer from $fromUserId for a ${this.isVideoCall ? 'VIDEO' : 'AUDIO'} call.');

    if (_internalCallIsActive && this.targetUserIdForCall != null && this.targetUserIdForCall != fromUserId) {
      debugPrint('WebRTCService ($myUserId): Ignoring offer from $fromUserId while in call with ${this.targetUserIdForCall}');
      return;
    }
    if (_internalCallIsActive && this.targetUserIdForCall == fromUserId && this.isVideoCall != (incomingCallType == 'video')) {
      debugPrint('WebRTCService ($myUserId): Call type changed for ongoing negotiation with $fromUserId. Resetting.');
      await hangUp();
    } else if (_internalCallIsActive && this.targetUserIdForCall == fromUserId) {
      debugPrint('WebRTCService ($myUserId): Re-negotiation (offer) from current partner $fromUserId. Using existing setup if compatible or resetting.');
      await _peerConnection?.close();
      _peerConnection = null;
    }

    this.targetUserIdForCall = fromUserId;
    _internalCallIsActive = false;

    try {
      await _createPeerConnection(offerVideo: this.isVideoCall);
      await _initializeLocalStreamAndTracks(videoIsEnabled: this.isVideoCall);

      if (_peerConnection == null || _localStream == null) {
        onCallFailed?.call("Failed to create peer connection or get local stream");
        return;
      }

      final sdp = sdpData['sdp'] as String?;
      final type = sdpData['type'] as String?;
      
      if (sdp == null || type == null) {
        throw Exception('Invalid SDP data: sdp=$sdp, type=$type');
      }
      
      await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      onSendAnswer(fromUserId, {
        'sdp': answer.sdp,
        'type': answer.type,
        'callType': this.isVideoCall ? 'video' : 'audio'
      });
      _internalCallIsActive = true;
      debugPrint('WebRTCService ($myUserId): Sent ${this.isVideoCall ? 'VIDEO' : 'AUDIO'} answer to $fromUserId');
    } catch (e, s) {
      _internalCallIsActive = false;
      debugPrint('Error in handleOffer for $myUserId: $e\nStack: $s');
      onCallFailed?.call("Error handling offer: ${e.toString()}");
    }
  }

  Future<void> handleAnswer(String fromUserId, Map<String, dynamic> sdpData) async {
    debugPrint('>>>>> WebRTCService ($myUserId): ENTERED handleAnswer from $fromUserId. SDP Type: ${sdpData['type']}');
    if (_peerConnection != null && this.targetUserIdForCall == fromUserId) {
      try {
        final sdp = sdpData['sdp'] as String?;
        final type = sdpData['type'] as String?;
        
        if (sdp == null || type == null) {
          throw Exception('Invalid SDP data in answer: sdp=$sdp, type=$type');
        }
        
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, type),
        );
        debugPrint('WebRTCService ($myUserId): Set remote description from answer successfully.');
      } catch (e, s) {
        debugPrint('Error in handleAnswer (setRemoteDescription) for $myUserId: $e\nStack: $s');
        onCallFailed?.call("Error processing answer: ${e.toString()}");
        await hangUp();
      }
    } else {
      debugPrint('WebRTCService ($myUserId): Received answer but PeerConnection is null or target mismatch. Current target: ${this.targetUserIdForCall}, Answer from: $fromUserId');
      if (_peerConnection == null) {
        onCallFailed?.call("Internal error handling answer (PC null)");
      }
    }
  }

  Future<void> handleCandidate(String fromUserId, Map<String, dynamic> candidateData) async {
    if (_peerConnection != null && this.targetUserIdForCall == fromUserId) {
      try {
        final candidate = RTCIceCandidate(
          candidateData['candidate'] as String,
          candidateData['sdpMid'] as String?,
          (candidateData['sdpMLineIndex'] as num?)?.toInt()
        );
        await _peerConnection!.addCandidate(candidate);
      } catch (e, s) {
        debugPrint('Error in handleCandidate (addCandidate) for $myUserId: $e\nStack: $s');
      }
    }
  }

  Future<void> hangUp() async {
    if (!_internalCallIsActive && _peerConnection == null && _localStream == null && remoteRenderer.srcObject == null) {
      if (onCallEnded != null && targetUserIdForCall != null) onCallEnded!();
      targetUserIdForCall = null;
      _internalCallIsActive = false;
      return;
    }
    debugPrint("WebRTCService ($myUserId): HANGING UP call with ${targetUserIdForCall ?? 'unknown'}. InternalCallActive: $_internalCallIsActive. PC: ${_peerConnection?.hashCode}");
    final bool wasActive = _internalCallIsActive;
    _internalCallIsActive = false;
    try {
      final tracks = _localStream?.getTracks();
      if (tracks != null) {
        for (var track in tracks) {
          await track.stop();
        }
      }
      if (localRenderer.srcObject != null) localRenderer.srcObject = null;
      await _localStream?.dispose();
      _localStream = null;
      await _disposePeerConnectionResources();
    } catch (e, s) {
      debugPrint("Error during hangUp for $myUserId: $e\nStack: $s");
    } finally {
      final endedTarget = targetUserIdForCall;
      targetUserIdForCall = null;
      if (wasActive && onCallEnded != null) {
        onCallEnded!();
        debugPrint("WebRTCService ($myUserId): onCallEnded callback invoked for target ${endedTarget ?? 'N/A'}.");
      }
    }
  }

  Future<void> dispose() async {
    debugPrint("WebRTCService ($myUserId): DISPOSING WebRTCService instance...");
    await hangUp();
    try {
      if (localRenderer.textureId != null) await localRenderer.dispose();
      if (remoteRenderer.textureId != null) await remoteRenderer.dispose();
    } catch (e) {
      debugPrint("Error disposing renderers: $e");
    }
    debugPrint("WebRTCService ($myUserId): WebRTCService instance disposed.");
  }

  // Getters for UI
  RTCVideoRenderer get localVideoRenderer => localRenderer;
  RTCVideoRenderer get remoteVideoRenderer => remoteRenderer;
  bool get isCallActive => _internalCallIsActive;
  String? get currentTargetUserId => targetUserIdForCall;
} 