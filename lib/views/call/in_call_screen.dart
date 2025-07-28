import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../view_models/call/call_viewmodel.dart';
import '../../models/user_model.dart';
import '../../services/webrtc_service.dart';

class InCallScreen extends StatelessWidget {
  final User callPartner;

  const InCallScreen({Key? key, required this.callPartner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CallViewModel>(
      builder: (context, viewModel, child) {
        final webrtcService = viewModel.webrtcService;
        final isVideoCall = viewModel.isVideoCall;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Status bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        viewModel.callStatusMessage ?? 'Connecting...',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Video/Audio content
                Expanded(
                  child: _buildCallContent(context, viewModel, webrtcService, isVideoCall),
                ),

                // Call controls
                _buildCallControls(context, viewModel, isVideoCall),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallContent(BuildContext context, CallViewModel viewModel, WebRTCService? webrtcService, bool isVideoCall) {
    if (isVideoCall) {
      return _buildVideoCallContent(context, webrtcService);
    } else {
      return _buildVoiceCallContent(context, viewModel);
    }
  }

  Widget _buildVideoCallContent(BuildContext context, WebRTCService? webrtcService) {
    if (webrtcService == null) {
      return const Center(
        child: Text(
          'Initializing video call...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // Remote video (full screen)
        if (webrtcService.remoteVideoRenderer.srcObject != null)
          RTCVideoView(
            webrtcService.remoteVideoRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          Container(
            color: Colors.grey[900],
            child: const Center(
              child: Text(
                'Waiting for remote video...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

        // Local video (picture-in-picture)
        if (webrtcService.localVideoRenderer.srcObject != null)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: RTCVideoView(
                  webrtcService.localVideoRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceCallContent(BuildContext context, CallViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[700],
            child: Text(
              callPartner.displayName.isNotEmpty 
                  ? callPartner.displayName[0].toUpperCase() 
                  : '?',
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            callPartner.displayName,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voice Call',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),
          if (viewModel.callStatusMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                viewModel.callStatusMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, CallViewModel viewModel, bool isVideoCall) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: Icons.mic,
            onPressed: viewModel.toggleAudio,
            backgroundColor: Colors.grey[700]!,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            onPressed: () {
              viewModel.endCall();
              Navigator.of(context).pop();
            },
            backgroundColor: Colors.red,
            isLarge: true,
          ),

          // Video toggle (only for video calls)
          if (isVideoCall)
            _buildControlButton(
              icon: Icons.videocam,
              onPressed: viewModel.toggleVideo,
              backgroundColor: Colors.grey[700]!,
            ),

          // Camera switch (only for video calls)
          if (isVideoCall)
            _buildControlButton(
              icon: Icons.switch_camera,
              onPressed: viewModel.switchCamera,
              backgroundColor: Colors.grey[700]!,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 48.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}