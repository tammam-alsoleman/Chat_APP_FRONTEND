// lib/views/chat/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import '../../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onRetry;

  const MessageBubble({
    Key? key, 
    required this.message, 
    required this.isMe,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 50 : 8,
          right: isMe ? 8 : 50,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender name (only show for other users' messages)
            if (!isMe) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderUsername,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            // Message content and status
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    message.textMessage,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  _buildStatusIcon(message.status),
                ]
              ],
            ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.sentAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isMe ? Colors.white70 : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
        );
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 16, color: Colors.white70);
      case MessageStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.error_outline, size: 16, color: Colors.yellowAccent),
        );
    }
  }

  String _formatTime(DateTime? sentAt) {
    if (sentAt == null) return '';
    
    // Show actual time in HH:MM format
    final hour = sentAt.hour.toString().padLeft(2, '0');
    final minute = sentAt.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }
}