import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class OnlineUsersBar extends StatelessWidget {
  final List<User> onlineUsers;
  final Function(User) onAddUser;
  final Function(User, bool) onInitiateCall;
  final VoidCallback? onRefresh;

  const OnlineUsersBar({
    Key? key,
    required this.onlineUsers,
    required this.onAddUser,
    required this.onInitiateCall,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onlineUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Online Users (${onlineUsers.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: Colors.grey),
                    onPressed: onRefresh,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),


          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // هامش للقائمة
              itemCount: onlineUsers.length,
              itemBuilder: (context, index) {
                final user = onlineUsers[index];
                return _buildUserCard(user, context);
              },
            ),
          ),
          // =================================================================
        ],
      ),
    );
  }

  Widget _buildUserCard(User user, BuildContext context) {
    return SizedBox(
      width: 100, // عرض ثابت لكل كرت
      child: InkWell(
        onTap: () => onAddUser(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => onInitiateCall(user, true),
                    child: Icon(Icons.videocam, size: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => onInitiateCall(user, false),
                    child: Icon(Icons.call, size: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}