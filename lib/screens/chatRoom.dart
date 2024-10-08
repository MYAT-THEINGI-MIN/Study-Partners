import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/Service/chatService.dart';
import 'package:sp_test/Service/messageItem.dart';
import 'package:sp_test/widgets/messageInput.dart';
import 'package:sp_test/screens/chatroomUserInfo.dart';

class ChatRoom extends StatefulWidget {
  final String receiverUserName;
  final String receiverUserId;

  ChatRoom({required this.receiverUserName, required this.receiverUserId});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final Chatservice _chatService = Chatservice(); 
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  List<File> _imageFiles = [];
  String? _receiverProfileUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReceiverProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchReceiverProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverUserId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _receiverProfileUrl = userDoc['profileImageUrl'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching receiver profile: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage(
      maxHeight: 800,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(
          pickedImages.map((pickedImage) => File(pickedImage.path)).toList(),
        );
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        _imageFiles.add(File(pickedImage.path));
      });
    }
  }

  Future<void> sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_messageController.text.isNotEmpty || _imageFiles.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_imageFiles.isNotEmpty) {
          for (var imageFile in _imageFiles) {
            await _chatService.sendImageMessage(
              widget.receiverUserId,
              imageFile,
            );
          }
          setState(() {
            _imageFiles = [];
          });
        } else {
          await _chatService.sendMessage(
            widget.receiverUserId,
            _messageController.text,
          );
        }
        _messageController.clear();
        _scrollToBottom();
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteMessage(DocumentReference messageRef) async {
    try {
      await messageRef.delete();
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatroomUserInfo(
                      userId: widget.receiverUserId,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: _receiverProfileUrl != null
                    ? NetworkImage(_receiverProfileUrl!)
                    : null,
              ),
            ),
            SizedBox(width: 10),
            Text(widget.receiverUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          if (_imageFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Images selected:'),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _imageFiles.asMap().entries.map((entry) {
                      int index = entry.key;
                      File imageFile = entry.value;
                      return Stack(
                        children: [
                          Image.file(
                            imageFile,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  TextButton(
                    onPressed: _pickImage,
                    child: Text('Add More'),
                  ),
                ],
              ),
            ),
          MessageInput(
            messageController: _messageController,
            onSend: sendMessage,
            onPickImage: _pickImage,
            onTakePhoto: _takePhoto,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
          _auth.currentUser!.uid, widget.receiverUserId),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        final messages = snapshot.data?.docs ?? [];
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

          bool isCurrentUser = message['senderId'] == _auth.currentUser!.uid;

          messageWidgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isCurrentUser && _receiverProfileUrl != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(_receiverProfileUrl!),
                  ),
                SizedBox(width: 10),
                Expanded(
                  child: MessageItem(
                    document: message,
                    auth: _auth,
                    onDelete: _deleteMessage,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          controller: _scrollController,
          children: messageWidgets,
        );
      },
    );
  }
}
