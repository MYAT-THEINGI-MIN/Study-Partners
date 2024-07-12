import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/Gptiles.dart';
import 'package:sp_test/screens/GpChat/createGp.dart';
import 'package:sp_test/screens/chatRoom.dart';
import 'package:sp_test/Service/chatService.dart';
import 'package:sp_test/widgets/user_title.dart';
import 'package:sp_test/widgets/CustomSearchBar.dart'; // Import CustomSearchBar

class ChatPg extends StatefulWidget {
  ChatPg({Key? key}) : super(key: key);

  @override
  _ChatUserListPgState createState() => _ChatUserListPgState();
}

class _ChatUserListPgState extends State<ChatPg>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _userStream;
  late Stream<QuerySnapshot> _groupStream;
  final Chatservice _chatService = Chatservice();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    checkAuthentication();
    _userStream = FirebaseFirestore.instance.collection('users').snapshots();
    _groupStream = FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: _auth.currentUser!.uid)
        .snapshots();

    _tabController = TabController(length: 2, vsync: this);

    // Add a listener to the scroll controller to handle refreshing
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {}
    });

    // Add a listener to the search controller to update the search text
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
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
        title: CustomSearchBar(
          controller: _searchController,
          hintText: 'Search...',
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
          onIconPressed: () {
            // Optionally handle search button press if needed
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Groups'),
            Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupList(),
          _buildUserList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateGroup(), // Navigate to CreateGroup screen
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _refreshUsers() async {
    // You can add any refreshing logic here, like fetching new data from Firestore
    setState(() {});
  }

  Widget _buildUserList() {
    return RefreshIndicator(
      onRefresh: _refreshUsers, // Method to call when refreshing
      child: StreamBuilder<QuerySnapshot>(
        stream: _userStream,
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            print("Error: ${userSnapshot.error}");
            return Text("Error");
          }

          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Filter out the current user's account and filter by search text
          var filteredUserDocs = userSnapshot.data!.docs
              .where((doc) => doc['email'] != _auth.currentUser!.email)
              .where((doc) => doc['username']
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()));

          return ListView.builder(
            controller: _scrollController, // Set the scroll controller
            itemCount: filteredUserDocs.length,
            itemBuilder: (context, index) {
              var doc = filteredUserDocs.elementAt(index);
              return UserTile(
                userDoc: doc,
                currentUserId: _auth.currentUser!.uid,
                chatService: _chatService,
                onDelete: _confirmDeleteChat,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupStream,
      builder: (context, groupSnapshot) {
        if (groupSnapshot.hasError) {
          print("Error: ${groupSnapshot.error}");
          return Text("Error");
        }

        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Filter groups by search text
        var filteredGroupDocs = groupSnapshot.data!.docs.where((doc) =>
            doc['groupName']
                .toString()
                .toLowerCase()
                .contains(_searchText.toLowerCase()));

        return ListView.builder(
          itemCount: filteredGroupDocs.length,
          itemBuilder: (context, index) {
            var doc = filteredGroupDocs.elementAt(index);
            return GroupTile(
              groupName: doc['groupName'],
              subject: doc['subject'],
              profileUrl: doc['profileUrl'] ?? '',
              groupId: doc.id,
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
    _searchController.dispose(); // Dispose the TextEditingController
    _tabController.dispose(); // Dispose the TabController
    super.dispose();
  }
}
