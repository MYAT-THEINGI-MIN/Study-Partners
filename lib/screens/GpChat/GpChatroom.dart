import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/GpChatService.dart';

class GpChatroom extends StatefulWidget {
  final String groupId;
  final String groupName;

  GpChatroom({
    required this.groupId,
    required this.groupName,
    required String gpProfileUrl,
    required String adminId,
  });

  @override
  _GpChatroomState createState() => _GpChatroomState();
}

class _GpChatroomState extends State<GpChatroom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GpChatService _gpChatService =
      GpChatService(); // Instance of GpChatService
  List<File> _imageFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      print(
          'Images selected: ${_imageFiles.map((image) => image.path).toList()}');
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        _imageFiles.add(File(pickedImage.path));
      });
      print('Photo taken: ${pickedImage.path}');
    }
  }

  Future<void> sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not authenticated.");
      return;
    }

    if (_messageController.text.isNotEmpty || _imageFiles.isNotEmpty) {
      setState(() {
        _isLoading = true; // Start loading
      });

      try {
        if (_imageFiles.isNotEmpty) {
          for (var imageFile in _imageFiles) {
            await _gpChatService.sendImageMessageToGroup(
                widget.groupId, imageFile);
          }
          setState(() {
            _imageFiles = []; // Reset the image files after sending
          });
        } else {
          await _gpChatService.sendMessageToGroup(
              widget.groupId, _messageController.text, user.uid);
        }
        _messageController.clear();
        print("Message sent successfully");
        _scrollToBottom();
      } catch (e) {
        print("Error sending message: $e");
      } finally {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    } else {
      print("Message is empty");
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

  void _showGroupDetails() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Group Details"),
          content: Text(
              "Group ID: ${widget.groupId}\nGroup Name: ${widget.groupName}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showGroupMembers() async {
    final members = await _gpChatService.getGroupMembers(widget.groupId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Group Members"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: members
                .map((member) => ListTile(
                      title: Text(member['name'] ?? member['email']),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'details') {
                _showGroupDetails();
              } else if (value == 'members') {
                _showGroupMembers();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'details',
                  child: Text('Group Details'),
                ),
                PopupMenuItem(
                  value: 'members',
                  child: Text('Members'),
                ),
              ];
            },
          ),
        ],
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _gpChatService.getGroupMessages(widget.groupId),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;
        List<Widget> messageWidgets = [];
        String? lastDate;

        for (var i = 0; i < messages.length; i++) {
          var message = messages[i];
          var messageData = message.data() as Map<String, dynamic>;
          var messageDate = (messageData['timestamp'] as Timestamp).toDate();
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

          bool isCurrentUser =
              messageData['senderId'] == _auth.currentUser!.uid;

          messageWidgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  CircleAvatar(
                    child: Text(messageData['senderId'][0].toUpperCase()),
                  ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (messageData.containsKey('imageUrl') &&
                            messageData['imageUrl'] != null)
                          Image.network(
                            messageData['imageUrl'],
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        if (messageData.containsKey('message') &&
                            messageData['message'] != null &&
                            messageData['message'].isNotEmpty)
                          Text(
                            messageData['message'],
                            style: TextStyle(
                              color:
                                  isCurrentUser ? Colors.white : Colors.black,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            DateFormat('hh:mm a').format(messageDate),
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
