import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
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

  void sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not authenticated.");
      return;
    }

    if (_messageController.text.isNotEmpty) {
      print("Sending message: ${_messageController.text}");
      try {
        await _chatservice.sendMessage(
          widget.receiverUserId,
          _messageController.text,
        );
        _messageController.clear();
        print("Message sent successfully");
      } catch (e) {
        print("Error sending message: $e");
      }
    } else {
      print("Message is empty");
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
          // Messages
          Expanded(
            child: _buildMessageList(),
          ),
          // User input
          MessageInput(
            messageController: _messageController,
            onSend: sendMessage,
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

        return ListView(
          children: messageWidgets,
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
