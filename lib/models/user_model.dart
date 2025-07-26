class User {
  final int userId;
  final String username;
  final String displayName;

  User({required this.userId, required this.username, required this.displayName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['user_name'],
      displayName: json['display_name'],
    );
  }
}