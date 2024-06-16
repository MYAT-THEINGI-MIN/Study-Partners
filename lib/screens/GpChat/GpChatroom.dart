import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sp_test/Service/chatService.dart';
import 'package:sp_test/Service/messageItem.dart';
import 'package:sp_test/screens/GpChat/EditGp.dart';
import 'package:sp_test/screens/GpChat/LeaveGp.dart';
import 'package:sp_test/widgets/messageInput.dart';

class GpChatRoom extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String gpProfileUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GpChatRoom({
    required this.groupId,
    required this.groupName,
    required this.gpProfileUrl,
    required String adminId,
  });

  @override
  _GpChatRoomState createState() => _GpChatRoomState();
}

class _GpChatRoomState extends State<GpChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final Chatservice _chatservice = Chatservice();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  List<File> _imageFiles = [];
  bool _isLoading = false;
  Map<String, String> _profileCache = {};

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
            await _chatservice.sendGroupImageMessage(widget.groupId, imageFile);
          }
          setState(() {
            _imageFiles = []; // Reset the image files after sending
          });
        } else {
          await _chatservice.sendGroupMessage(
              widget.groupId, _messageController.text);
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

  void _deleteMessage(DocumentReference messageRef) async {
    try {
      await messageRef.delete();
      print("Message deleted successfully");
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

  Future<Map<String, dynamic>> fetchGroupDetails() async {
    try {
      DocumentSnapshot groupSnapshot = await widget._firestore
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        return groupSnapshot.data() as Map<String, dynamic>;
      } else {
        throw 'Group not found';
      }
    } catch (e) {
      print('Error fetching group details: $e');
      return {};
    }
  }

  Future<String> _fetchUserProfileUrl(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId]!;
    }
    try {
      DocumentSnapshot userSnapshot =
          await widget._firestore.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        String profileUrl = userSnapshot['profileUrl'] ?? '';
        _profileCache[userId] = profileUrl;
        return profileUrl;
      } else {
        throw 'User not found';
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () async {
                // Navigate to edit group screen
                var result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGroupPage(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                      groupSubject: '',
                      gpProfileUrl: '',
                    ),
                  ),
                );

                // Handle any result if needed from EditGroupPage
                if (result != null) {
                  // Perform any necessary updates
                }
              },
              child: widget.gpProfileUrl.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(widget.gpProfileUrl),
                    )
                  : CircleAvatar(
                      child: Icon(Icons.group),
                    ),
            ),
            SizedBox(width: 8),
            Text(widget.groupName),
          ],
        ),
        actions: [
          // Popup menu button for details and leave group
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Details'),
                  ],
                ),
                value: 'details',
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app),
                    SizedBox(width: 8),
                    Text('Leave Group'),
                  ],
                ),
                value: 'leave',
              ),
            ],
            onSelected: (value) {
              if (value == 'details') {
                _showGroupDetails();
              } else if (value == 'leave') {
                _leaveGroup();
              }
            },
          )
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
      stream: _chatservice.getMessagesForGroup(widget.groupId),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Loading...'),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          );
        }

        final messages = snapshot.data!.docs;
        List<Widget> messageWidgets = [];
        String? lastDate;

        for (var i = 0; i < messages.length; i++) {
          var msg = messages[i];
          var messageDate = (msg['timestamp'] as Timestamp).toDate();
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

          bool isCurrentUser = msg['senderId'] == _auth.currentUser!.uid;

          messageWidgets.add(
            FutureBuilder(
              future: _fetchUserProfileUrl(msg['senderId']),
              builder: (context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox.shrink(); // Hide until profile URL is fetched
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isCurrentUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      CircleAvatar(
                        backgroundImage: NetworkImage(snapshot.data ?? ''),
                      ),
                    SizedBox(width: 10),
                    Expanded(
                      child: MessageItem(
                        document: msg,
                        auth: _auth,
                        onDelete: _deleteMessage,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }

        return Expanded(
          child: ListView(
            reverse: true, // Show latest messages at the bottom
            controller: _scrollController,
            children: messageWidgets.reversed.toList(),
          ),
        );
      },
    );
  }

  void _showGroupDetails() async {
    Map<String, dynamic> groupDetails = await fetchGroupDetails();

    if (groupDetails.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Group Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group Name: ${groupDetails['groupName']}'),
                SizedBox(height: 8),
                Text('Subject: ${groupDetails['subject']}'),
                SizedBox(height: 8),
                Text('Admin Name: ${groupDetails['adminId']}'),
                SizedBox(height: 8),
                Text(
                    'Created At: ${DateFormat('yMMMd').format(groupDetails['timestamp'].toDate())}'),
                SizedBox(height: 8),
                Text('Member Count: ${groupDetails['members'].length}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      // Handle case where group details couldn't be fetched
      print('Failed to fetch group details.');
    }
  }

  Future<void> _leaveGroup() async {
    try {
      // Implement logic to leave the group
      // For example:
      // LeaveGroupService leaveGroupService = LeaveGroupService();
      // await leaveGroupService.leaveGroup(widget.groupId);
      Navigator.pop(context); // Navigate back to previous screen
    } catch (e) {
      print('Error leaving group: $e');
      // Handle error leaving group
    }
  }
}
