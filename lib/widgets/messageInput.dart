import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController messageController;
  final Function() onSend;
  final Function() onPickImage;
  final Function() onTakePhoto;
  final bool isLoading;
  final double uploadProgress;

  MessageInput({
    required this.messageController,
    required this.onSend,
    required this.onPickImage,
    required this.onTakePhoto,
    required this.isLoading,
    this.uploadProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoading)
          LinearProgressIndicator(
            value: uploadProgress,
          ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.photo),
              onPressed: onPickImage,
            ),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: onTakePhoto,
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
              onPressed:
                  isLoading ? null : onSend, // Disable the button when loading
            ),
          ],
        ),
      ],
    );
  }
}
