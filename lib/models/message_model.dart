enum MessageStatus { sending, sent, failed }

class Message {
  final int? messageId;
  final int groupId;
  final int senderId;
  final String senderUsername;
  final DateTime? sentAt;
  final String textMessage;

  final String clientMessageId;
  final MessageStatus status;

  Message({
    this.messageId,
    required this.senderId,
    required this.groupId,
    required this.senderUsername,
    this.sentAt,
    required this.textMessage,
    required this.clientMessageId,
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Use null-aware operators to provide default values if a key is missing.
    return Message(
      messageId: json['message_id'] as int?,
      groupId: json['group_id'] as int? ?? 0, // Provide a default group ID like 0 or handle it
      senderId: json['sender_id'] as int? ?? 0, // Provide a default sender ID
      senderUsername: json['user_name'] as String? ?? 'Unknown User', // Default username

      // Check for null before parsing the date
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : DateTime.now(),

      textMessage: json['text_message'] as String? ?? '', // Default text message

      // Client message ID might not be in every payload from the server
      clientMessageId: json['client_message_id'] as String? ?? '',
    );
  }

  Message copyWith({
    int? messageId,
    DateTime? sentAt,
    MessageStatus? newStatus,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      groupId: this.groupId,
      senderId: this.senderId,
      senderUsername: this.senderUsername,
      sentAt: sentAt ?? this.sentAt,
      textMessage: this.textMessage,
      clientMessageId: this.clientMessageId,
      status: newStatus ?? this.status,
    );
  }
}