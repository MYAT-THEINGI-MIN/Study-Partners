import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  MessageInput({
    required this.messageController,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.image),
          onPressed: onPickImage,
        ),
        Expanded(
          child: TextField(
            controller: messageController,
            decoration: InputDecoration(
              hintText: 'Enter your message...',
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: onSend,
        ),
      ],
    );
  }
}
