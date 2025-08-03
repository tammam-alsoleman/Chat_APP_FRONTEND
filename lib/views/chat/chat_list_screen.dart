// lib/views/chat/chat_list_screen.dart

import 'package:chat_app_frontend/shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/locator.dart';
import '../../models/group_model.dart';
import '../../repositories/auth_repository.dart';
import '../../shared/enums.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../view_models/chat/chat_list_viewmodel.dart';
import '../../view_models/user_provider.dart';
import 'chat_screen.dart';
import '../auth/login_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  late ChatListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Create the ViewModel from the service locator
    _viewModel = sl<ChatListViewModel>();
    
    // Fetch the chats as soon as the screen is ready.
    // The socket connection is already handled in AuthWrapper/AuthRepository,
    // so we don't need to call connectAndListen() here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.fetchChats();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app becomes visible
    if (state == AppLifecycleState.resumed) {
      _viewModel.fetchChats();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    print("--- 1. Logout process started ---");
    try {
      // Get the AuthRepository and UserProvider before any async gaps.
      final authRepository = sl<AuthRepository>();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Perform all data-clearing operations first.
      await authRepository.logout();
      print("--- 2. authRepository.logout() completed successfully ---");

      // Clear the user from the provider.
      userProvider.clearUser();
      print("--- 3. UserProvider cleared ---");

      // THE FIX: Check if the widget is still mounted AFTER all async work
      // and BEFORE using the context for navigation.
      if (!mounted) return;

      // Now, perform the navigation as the very last step.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
      print("--- 4. Navigation to LoginScreen initiated ---");

    } catch (e) {
      print("--- ❌ ERROR during logout process: $e ---");
      // Also check if mounted before showing a snackbar.
      if (mounted) {
        AppUtils.showSnackBar(context, "Logout failed. Please try again.", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Users',
            onPressed: () {
              // TODO: Navigate to SearchScreen
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.state == ViewState.Busy) {
            return const LoadingIndicator();
          }

          if (_viewModel.state == ViewState.Error && _viewModel.failure != null) {
            return Center(child: Text('Error: ${_viewModel.failure!.message}'));
          }

          if (_viewModel.chats.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'No Conversations Yet',
              message: 'Tap the button below to start a new chat.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => _viewModel.fetchChats(),
            child: ListView.builder(
              itemCount: _viewModel.chats.length,
              itemBuilder: (context, index) {
                final chat = _viewModel.chats[index];
                return _ChatListItem(chat: chat, viewModel: _viewModel);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to our new screen
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
          _viewModel.fetchChats();
        },
        tooltip: 'New Chat',
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }
}

/// The private widget for a single item in the list remains the same.
class _ChatListItem extends StatelessWidget {
  final Group chat;
  final ChatListViewModel viewModel;
  const _ChatListItem({
    Key? key,
    required this.chat,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(chat.groupName.isNotEmpty ? chat.groupName[0].toUpperCase() : '?'),
      ),
      title: Text(chat.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Last message will appear here...'),
      trailing: const Text('Time'),
      onTap: () async {
        final currentUser = Provider.of<UserProvider>(context, listen: false).user;
        if (currentUser != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(chat: chat, currentUser: currentUser),
            ),
          );
          viewModel.fetchChats();
        }
      },
    );
  }
}