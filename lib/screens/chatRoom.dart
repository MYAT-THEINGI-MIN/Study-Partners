import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/Service/chatService.dart';
import 'package:sp_test/widgets/messageInput.dart';
import 'package:sp_test/widgets/messageItem.dart';

class ChatRoom extends StatefulWidget {
  final String receiverUserName;
  final String receiverUserId;

  ChatRoom({required this.receiverUserName, required this.receiverUserId});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final Chatservice _chatservice = Chatservice();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  List<File>? _imageFiles;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImages = await picker.getMultiImage(
      maxHeight: 800,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _imageFiles =
            pickedImages.map((pickedImage) => File(pickedImage.path)).toList();
      });
      print(
          'Images selected: ${_imageFiles!.map((image) => image.path).toList()}');
    }
  }

  void sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not authenticated.");
      return;
    }

    if (_messageController.text.isNotEmpty || _imageFiles != null) {
      try {
        if (_imageFiles != null) {
          for (var imageFile in _imageFiles!) {
            await _chatservice.sendImageMessage(
                widget.receiverUserId, imageFile);
          }
          setState(() {
            _imageFiles = null; // Reset the image files after sending
          });
        } else {
          await _chatservice.sendMessage(
              widget.receiverUserId, _messageController.text);
        }
        _messageController.clear();
        print("Message sent successfully");

        // Scroll to bottom after sending a message
        _scrollToBottom();
      } catch (e) {
        print("Error sending message: $e");
      }
    } else {
      print("Message is empty");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _deleteMessage(DocumentReference messageRef) async {
    try {
      await messageRef.delete();
      print("Message deleted successfully");
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          if (_imageFiles != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Images selected:'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _imageFiles!.map((imageFile) {
                      return Image.file(
                        imageFile,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          MessageInput(
            messageController: _messageController,
            onSend: sendMessage,
            onPickImage: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatservice.getMessages(
          _auth.currentUser!.uid, widget.receiverUserId),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        final messages = snapshot.data!.docs;
        List<Widget> messageWidgets = [];
        String? lastDate;

        for (var i = 0; i < messages.length; i++) {
          var message = messages[i];
          var messageDate = (message['timestamp'] as Timestamp).toDate();
          var formattedDate = DateFormat('yMMMd').format(messageDate);

          if (lastDate != formattedDate) {
            lastDate = formattedDate;
            messageWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }

          messageWidgets.add(
            MessageItem(
              document: message,
              auth: _auth,
              onDelete: _deleteMessage,
            ),
          );
        }

        // Scroll to bottom whenever messages update
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView(
          controller: _scrollController,
          children: messageWidgets,
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
