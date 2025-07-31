import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/call/call_viewmodel.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/online_users_bar.dart';
import '../../shared/widgets/user_search_bar.dart';
import '../../shared/widgets/call_list.dart';
import '../../services/locator.dart';
import 'in_call_screen.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({Key? key}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  late CallViewModel _callViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callViewModel = sl<CallViewModel>();
    
    // Refresh online users when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callViewModel.refreshOnlineUsers();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh online users when app becomes visible
    if (state == AppLifecycleState.resumed) {
      _callViewModel.refreshOnlineUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _callViewModel,
      child: Consumer<CallViewModel>(
        builder: (context, viewModel, child) {
          // Show in-call screen if currently in a call
          if (viewModel.isInCall && viewModel.currentCallPartner != null) {
            return InCallScreen(
              callPartner: viewModel.currentCallPartner!,
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Calls'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                // Debug button to test online users
                IconButton(
                  icon: const Icon(Icons.bug_report),
                  onPressed: () {
                    print('[CallScreen] Debug: Current online users count: ${viewModel.onlineUsers.length}');
                    print('[CallScreen] Debug: Online users: ${viewModel.onlineUsers.map((u) => '${u.displayName} (ID: ${u.userId})').join(', ')}');
                    viewModel.refreshOnlineUsers();
                  },
                ),
                // Debug button to test incoming call
                IconButton(
                  icon: const Icon(Icons.call_received),
                  onPressed: () {
                    if (viewModel.onlineUsers.isNotEmpty) {
                      final testUser = viewModel.onlineUsers.first;
                      print('[CallScreen] Debug: Testing incoming call from ${testUser.displayName}');
                      // Simulate incoming call
                      viewModel.onIncomingCall(testUser.userId, {
                        'callType': 'video',
                        'sdp': 'test-sdp',
                      });
                    }
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Online Users Bar
                OnlineUsersBar(
                  onlineUsers: viewModel.onlineUsers,
                  onAddUser: viewModel.addUserToCallList,
                  onInitiateCall: (user, isVideo) => viewModel.initiateCall(user, isVideo: isVideo),
                  onRefresh: viewModel.refreshOnlineUsers,
                ),
                
                // Search Bar
                UserSearchBar(
                  onSearch: viewModel.searchUsers,
                  onClear: viewModel.clearSearch,
                  searchQuery: viewModel.searchQuery,
                ),
                
                // Search Results or Call List
                Expanded(
                  child: _buildMainContent(viewModel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(CallViewModel viewModel) {
    if (viewModel.isSearching) {
      return _buildSearchResults(viewModel);
    } else {
      return _buildCallList(viewModel);
    }
  }

  Widget _buildSearchResults(CallViewModel viewModel) {
    if (viewModel.searchResults.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Users Found',
        message: 'Try searching with a different name',
        icon: Icons.search_off,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.searchResults.length,
      itemBuilder: (context, index) {
        final user = viewModel.searchResults[index];
        return _buildUserTile(
          user,
          onTap: () => viewModel.addUserToCallList(user),
          showAddButton: true,
        );
      },
    );
  }

  Widget _buildCallList(CallViewModel viewModel) {
    if (viewModel.callList.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Users in Call List',
        message: 'Add users to start calling',
        icon: Icons.people_outline,
      );
    }

    return CallList(
      users: viewModel.callList,
      onRemoveUser: viewModel.removeUserFromCallList,
      onInitiateCall: viewModel.initiateCall,
    );
  }

  Widget _buildUserTile(
    User user, {
    required VoidCallback onTap,
    bool showAddButton = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(user.username),
        trailing: showAddButton
            ? IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: onTap,
              )
            : null,
        onTap: showAddButton ? onTap : null,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
} 