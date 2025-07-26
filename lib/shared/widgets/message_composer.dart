// lib/views/chat/widgets/message_composer.dart

import 'package:flutter/material.dart';

class MessageComposer extends StatefulWidget {
  final Function(String) onSendMessage;
  const MessageComposer({Key? key, required this.onSendMessage}) : super(key: key);

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
      // Keep the keyboard focused for quick follow-up messages
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea( // Ensures the composer is not obscured by system UI
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}