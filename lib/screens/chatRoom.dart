import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/Service/chatService.dart';

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
            widget.receiverUserId, _messageController.text);
        _messageController.clear();
        print("Message sent successfully");
      } catch (e) {
        print("Error sending message: $e");
      }
    } else {
      print("Message is empty");
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
          _buildMessageInput(),
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

        return ListView(
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    var alignment = (data['senderId'] == _auth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: alignment,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue, // Set the background color to blue
            borderRadius:
                BorderRadius.circular(20), // Increase the border radius
          ),
          child: Text(
            data['message'],
            style: TextStyle(
                fontSize: 16, color: Colors.white), // Set text color to white
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Enter Message',
              ),
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
