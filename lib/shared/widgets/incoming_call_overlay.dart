import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class IncomingCallOverlay extends StatelessWidget {
  final User caller;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isVideoCall;

  const IncomingCallOverlay({
    Key? key,
    required this.caller,
    required this.onAccept,
    required this.onDecline,
    this.isVideoCall = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Caller info
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Caller avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        caller.displayName.isNotEmpty 
                            ? caller.displayName[0].toUpperCase() 
                            : '?',
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Caller name
                    Text(
                      caller.displayName,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Call type
                    Text(
                      isVideoCall ? 'Incoming Video Call' : 'Incoming Voice Call',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Call type icon
                    Icon(
                      isVideoCall ? Icons.videocam : Icons.call,
                      size: 32,
                      color: isVideoCall ? Colors.blue : Colors.green,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Call controls
              Container(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline button
                    _buildControlButton(
                      icon: Icons.call_end,
                      backgroundColor: Colors.red,
                      onPressed: onDecline,
                      isLarge: true,
                    ),
                    
                    // Accept button
                    _buildControlButton(
                      icon: isVideoCall ? Icons.videocam : Icons.call,
                      backgroundColor: Colors.green,
                      onPressed: onAccept,
                      isLarge: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 80.0 : 60.0;
    final iconSize = isLarge ? 40.0 : 30.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
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