/// Represents a single chat group/conversation.
class Group {
  final int groupId;
  final String groupName;
  final DateTime createdAt;
  // Future fields: unreadCount, lastMessage, etc.

  Group({
    required this.groupId,
    required this.groupName,
    required this.createdAt,
  });

  /// A factory constructor for creating a new Group instance from a map.
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['group_id'],
      groupName: json['group_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}