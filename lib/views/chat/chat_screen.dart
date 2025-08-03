// lib/views/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../shared/enums.dart';
import '../../shared/utils.dart';
import '../../view_models/chat/chat_viewmodel.dart';
import '../../shared/widgets/message_bubble.dart'; 
import '../../shared/widgets/message_composer.dart';
import '../../view_models/user_provider.dart';

class ChatScreen extends StatelessWidget {
  final Group chat; // Pass the chat object to get its name and ID
  final User? currentUser; // Pass the current user directly

  const ChatScreen({Key? key, required this.chat, this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = currentUser ?? userProvider.user;
        
        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(chat.groupName),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user data...'),
                ],
              ),
            ),
          );
        }
        
        return ChangeNotifierProvider(
          create: (_) => ChatViewModel(chatId: chat.groupId, currentUser: user),
          child: Scaffold(
            appBar: AppBar(
              title: Text(chat.groupName),
            ),
            body: _ChatView(currentUser: user),
          ),
        );
      },
    );
  }
}

class _ChatView extends StatefulWidget {
  final User currentUser;
  
  const _ChatView({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {

  @override
  Widget build(BuildContext context) {
    // Use `context.watch` to listen for changes and rebuild the UI
    final viewModel = context.watch<ChatViewModel>();

    // Use a listener for one-time actions like showing an error SnackBar
    if (viewModel.state == ViewState.Error && viewModel.failure != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppUtils.showSnackBar(context, viewModel.failure!.message, isError: true);
      });
    }

    return Column(
      children: [
        Expanded(
          child: _buildMessageList(viewModel),
        ),
        MessageComposer(
          onSendMessage: (text) {
            // Use `context.read` for one-time actions like calling a function
            context.read<ChatViewModel>().sendMessage(text);
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(ChatViewModel viewModel) {
  // 1. Handle the Busy state
    if (viewModel.state == ViewState.Busy) {
      // If we are busy, show a centered loading indicator.
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Handle the Error state (optional, but good practice)
    if (viewModel.state == ViewState.Error && viewModel.failure != null) {
      return Center(
        child: Text("Error: ${viewModel.failure!.message}"),
      );
    }

    // 3. Handle the Empty state
    if (viewModel.messages.isEmpty) {
      return const Center(
        child: Text('No messages yet. Say something!'),
      );
    }

    return ListView.builder(
      reverse: true, // This makes the list start from the bottom
      itemCount: viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = viewModel.messages[index];
        final isMe = message.senderId == widget.currentUser.userId;
        return MessageBubble(
          message: message,
          isMe: isMe,
          onRetry: message.status == MessageStatus.failed
            ? () => _retryMessage(context, message)
            : null,
        );
      },
    );
  }

  void _retryMessage(BuildContext context, Message message) {
    final viewModel = context.read<ChatViewModel>();
    viewModel.retryMessage(message);
  }
}