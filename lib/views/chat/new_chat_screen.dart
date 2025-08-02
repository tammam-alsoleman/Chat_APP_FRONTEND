// lib/views/chat/new_chat_screen.dart
import 'package:chat_app_frontend/views/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/locator.dart';
import '../../shared/enums.dart';
import '../../shared/utils.dart';
import '../../view_models/chat/new_chat_viewmodel.dart';
import '../../view_models/user_provider.dart';
import 'chat_screen.dart'; // We'll navigate here on success
import '../../models/group_model.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser == null) {
      // This should ideally not happen if routing is correct
      return const Scaffold(body: Center(child: Text('Error: User not found.')));
    }

    return ChangeNotifierProvider(
      create: (_) => NewChatViewModel(currentUser: currentUser),
      child: const _NewChatView(),
    );
  }
}

class _NewChatView extends StatefulWidget {
  const _NewChatView({Key? key}) : super(key: key);

  @override
  __NewChatViewState createState() => __NewChatViewState();
}

class __NewChatViewState extends State<_NewChatView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleStateChanges(BuildContext context, NewChatViewModel viewModel) {
    if (viewModel.state == ViewState.Success && viewModel.createdGroupId != null) {
      // Create a temporary Group object to pass to the chat screen
      final tempGroup = Group(
        // Use the integer groupId from your backend's eventual response, for now this is fine
        groupId: int.tryParse(viewModel.createdGroupId!) ?? 0,
        groupName: viewModel.selectedUsers.map((u) => u.displayName).join(', '),
        createdAt: DateTime.now(),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ===== THE FIX IS HERE =====
        // We navigate to the ChatListScreen first and then push the new ChatScreen.
        // This ensures a clean navigation stack.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()), // Go back to the root
              (route) => false,
        );
        // Then push the new chat on top of the list.
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(chat: tempGroup, currentUser: null)),
        );
        // =========================
      });
    } else if (viewModel.state == ViewState.Error && viewModel.failure != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppUtils.showSnackBar(context, viewModel.failure!.message, isError: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NewChatViewModel>();
    _handleStateChanges(context, viewModel);

    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search for users...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: viewModel.searchUsers,
            ),
          ),

          // Selected Users
          if (viewModel.selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                children: viewModel.selectedUsers
                    .map((user) => Chip(
                  label: Text(user.displayName),
                  onDeleted: () => viewModel.deselectUser(user),
                ))
                    .toList(),
              ),
            ),

          // Search Results
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.searchResults.length,
              itemBuilder: (context, index) {
                final user = viewModel.searchResults[index];
                return ListTile(
                  title: Text(user.displayName),
                  subtitle: Text(user.username),
                  onTap: () {
                    viewModel.selectUser(user);
                    _searchController.clear();
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.selectedUsers.isEmpty || viewModel.state == ViewState.Busy
            ? null // Disable button if no users are selected or if busy
            : viewModel.createGroup,
        tooltip: 'Create Chat',
        child: viewModel.state == ViewState.Busy
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }
}