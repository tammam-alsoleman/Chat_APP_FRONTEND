import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class OnlineUsersBar extends StatelessWidget {
  final List<User> onlineUsers;
  final Function(User) onAddUser;
  final Function(User, bool)? onInitiateCall; // Added for direct calling
  final VoidCallback? onRefresh; // Added for manual refresh

  const OnlineUsersBar({
    Key? key,
    required this.onlineUsers,
    required this.onAddUser,
    this.onInitiateCall,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('[OnlineUsersBar] Building with ${onlineUsers.length} users: ${onlineUsers.map((u) => u.displayName).join(', ')}');
    if (onlineUsers.isEmpty) {
      print('[OnlineUsersBar] No online users, hiding bar');
      return const SizedBox.shrink();
    }

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Online Users (${onlineUsers.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.videocam,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    if (onRefresh != null)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: onRefresh,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: onlineUsers.length,
              itemBuilder: (context, index) {
                final user = onlineUsers[index];
                return _buildUserCard(user, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user, BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => onAddUser(user),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user.displayName.isNotEmpty 
                        ? user.displayName[0].toUpperCase() 
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${user.userId}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Video call button
                    if (onInitiateCall != null)
                      GestureDetector(
                        onTap: () => onInitiateCall!(user, true),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.videocam,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
                    // Audio call button
                    if (onInitiateCall != null)
                      GestureDetector(
                        onTap: () => onInitiateCall!(user, false),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.call,
                            size: 14,
                            color: Colors.green[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 