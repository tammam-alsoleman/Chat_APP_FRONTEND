import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class CallList extends StatelessWidget {
  final List<User> users;
  final Function(User) onRemoveUser;
  final Function(User, {bool isVideo}) onInitiateCall;

  const CallList({
    Key? key,
    required this.users,
    required this.onRemoveUser,
    required this.onInitiateCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user, context);
      },
    );
  }

  Widget _buildUserCard(User user, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user.displayName.isNotEmpty 
                    ? user.displayName[0].toUpperCase() 
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.username,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Call Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice Call Button
                _buildCallButton(
                  context,
                  icon: Icons.call,
                  color: Colors.green,
                  onPressed: () => onInitiateCall(user, isVideo: false),
                ),
                
                const SizedBox(width: 8),
                
                // Video Call Button
                _buildCallButton(
                  context,
                  icon: Icons.videocam,
                  color: Colors.blue,
                  onPressed: () => onInitiateCall(user, isVideo: true),
                ),
                
                const SizedBox(width: 8),
                
                // Remove Button
                _buildCallButton(
                  context,
                  icon: Icons.remove_circle_outline,
                  color: Colors.red,
                  onPressed: () => onRemoveUser(user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        tooltip: icon == Icons.call 
            ? 'Voice Call' 
            : icon == Icons.videocam 
                ? 'Video Call' 
                : 'Remove',
      ),
    );
  }
} 