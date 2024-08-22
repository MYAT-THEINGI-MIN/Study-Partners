import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/screens/GpChat/Gptiles.dart';
import 'package:sp_test/screens/chatroom.dart';
import 'package:sp_test/widgets/CustomSearchBar.dart';

class GpAndFriChatPg extends StatefulWidget {
  @override
  _GpAndFriChatPgState createState() => _GpAndFriChatPgState();
}

class _GpAndFriChatPgState extends State<GpAndFriChatPg>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _groupStream;
  late Stream<QuerySnapshot> _chatRoomStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    checkAuthentication();

    _groupStream = FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: _auth.currentUser!.uid)
        .snapshots();

    _chatRoomStream = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('userIds', arrayContains: _auth.currentUser!.uid)
        .snapshots();

    _tabController = TabController(length: 2, vsync: this); // Two tabs

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
          onIconPressed: () {},
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
          _buildFriendChatList(),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupStream,
      builder: (context, groupSnapshot) {
        if (groupSnapshot.hasError) {
          return Text("Error loading groups");
        }

        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var filteredGroupDocs = groupSnapshot.data!.docs.where((doc) {
          final groupName = doc['groupName']?.toString().toLowerCase() ?? '';
          return groupName.contains(_searchText.toLowerCase());
        }).toList();

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

  Widget _buildFriendChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatRoomStream,
      builder: (context, chatRoomSnapshot) {
        if (chatRoomSnapshot.hasError) {
          return Center(
              child:
                  Text("Error loading chat rooms: ${chatRoomSnapshot.error}"));
        }

        if (chatRoomSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!chatRoomSnapshot.hasData || chatRoomSnapshot.data!.docs.isEmpty) {
          return Center(child: Text('No chat rooms found.'));
        }

        var chatRooms = chatRoomSnapshot.data!.docs.where((doc) {
          final userIds = (doc['userIds'] as List<dynamic>).cast<String>();
          return userIds.contains(_auth.currentUser!.uid);
        }).toList();

        List<String> userIds = chatRooms
            .expand((doc) => (doc['userIds'] as List<dynamic>).cast<String>())
            .where((id) => id != _auth.currentUser!.uid) // Exclude current user
            .toSet()
            .toList();

        Future<Map<String, Map<String, String>>> fetchUserDetails(
            List<String> userIds) async {
          final userDocs = await Future.wait(userIds.map((id) =>
              FirebaseFirestore.instance.collection('users').doc(id).get()));
          return Map.fromEntries(userDocs.map((doc) => MapEntry(doc.id, {
                'username': doc['username'] ?? 'Unknown',
                'profileImageUrl': doc['profileImageUrl'] ?? '',
              })));
        }

        return FutureBuilder<Map<String, Map<String, String>>>(
          future: fetchUserDetails(userIds),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Center(
                  child:
                      Text("Error loading user data: ${userSnapshot.error}"));
            }

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            var userDetails = userSnapshot.data ?? {};

            var filteredChatRooms = chatRooms.where((chatRoomDoc) {
              final userIdsInRoom =
                  (chatRoomDoc['userIds'] as List<dynamic>).cast<String>();
              final receiverUserId = userIdsInRoom
                  .firstWhere((id) => id != _auth.currentUser!.uid);

              final receiverDetails = userDetails[receiverUserId] ??
                  {
                    'username': 'Unknown',
                    'profileImageUrl': '',
                  };

              final receiverUserName = receiverDetails['username'] ?? '';

              return receiverUserName
                  .toLowerCase()
                  .contains(_searchText.toLowerCase());
            }).toList();

            return ListView.builder(
              itemCount: filteredChatRooms.length,
              itemBuilder: (context, index) {
                var chatRoomDoc = filteredChatRooms[index];
                String chatRoomId = chatRoomDoc.id;
                List<String> userIdsInRoom =
                    (chatRoomDoc['userIds'] as List<dynamic>).cast<String>();
                String receiverUserId = userIdsInRoom
                    .firstWhere((id) => id != _auth.currentUser!.uid);
                var receiverDetails = userDetails[receiverUserId] ??
                    {
                      'username': 'Unknown',
                      'profileImageUrl': '',
                    };

                return GestureDetector(
                  onLongPress: () {
                    _showDeleteConfirmationDialog(chatRoomId);
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: receiverDetails['profileImageUrl']!
                              .isNotEmpty
                          ? NetworkImage(receiverDetails['profileImageUrl']!)
                          : null,
                      child: receiverDetails['profileImageUrl']!.isEmpty
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(receiverDetails['username'] ?? 'Unknown'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoom(
                            receiverUserName: receiverDetails['username']!,
                            receiverUserId: receiverUserId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String chatRoomId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Chat Room"),
          content: Text("Are you sure you want to delete this chat room?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(chatRoomId)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
