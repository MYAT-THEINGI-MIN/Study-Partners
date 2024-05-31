import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/chatRoom.dart';
import 'package:sp_test/Service/chatService.dart';
import 'package:sp_test/widgets/user_title.dart';

class ChatUserListPg extends StatefulWidget {
  ChatUserListPg({Key? key}) : super(key: key);

  @override
  _ChatUserListPgState createState() => _ChatUserListPgState();
}

class _ChatUserListPgState extends State<ChatUserListPg> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _userStream;
  final Chatservice _chatService = Chatservice();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    checkAuthentication();
    _userStream = FirebaseFirestore.instance.collection('users').snapshots();

    // Listen to the refresh stream and call setState when a refresh is triggered

    // Add a listener to the scroll controller to handle refreshing
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {}
    });
  }

  void checkAuthentication() async {
    User? user = _auth.currentUser;
    if (user == null) {
      await _auth.signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Friends"),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUsers, // Method to call when refreshing
        child: _buildUserList(),
      ),
    );
  }

  Future<void> _refreshUsers() async {
    // You can add any refreshing logic here, like fetching new data from Firestore
    setState(() {});
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          print("Error: ${userSnapshot.error}");
          return Text("Error");
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Filter out the current user's account
        var filteredDocs = userSnapshot.data!.docs
            .where((doc) => doc['email'] != _auth.currentUser!.email);

        return ListView.builder(
          controller: _scrollController, // Set the scroll controller
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var doc = filteredDocs.elementAt(index);
            return UserTile(
              userDoc: doc,
              currentUserId: _auth.currentUser!.uid,
              chatService: _chatService,
              onDelete: _confirmDeleteChat,
            );
          },
        );
      },
    );
  }

  void _confirmDeleteChat(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteChat(uid);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String uid) async {
    // Get the current user's ID
    final currentUserId = _auth.currentUser!.uid;

    // Fetch and delete messages where the current user is the sender and the other user is the receiver
    QuerySnapshot sentMessages = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: uid)
        .get();

    // Fetch and delete messages where the other user is the sender and the current user is the receiver
    QuerySnapshot receivedMessages = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: uid)
        .where('receiverId', isEqualTo: currentUserId)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in sentMessages.docs) {
      batch.delete(doc.reference);
    }

    for (var doc in receivedMessages.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the ScrollController
    super.dispose();
  }
}
