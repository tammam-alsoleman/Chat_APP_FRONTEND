class User {
  final int userId;
  final String username;
  final String displayName;

  User({required this.userId, required this.username, required this.displayName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? json['userId'],
      username: json['user_name'] ?? json['username'],
      displayName: json['display_name'] ?? json['displayName'] ?? json['username'] ?? 'Unknown User',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
    };
  }
}