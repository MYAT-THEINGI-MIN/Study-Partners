import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/screens/chatRoom.dart';

class ChatUserListPg extends StatefulWidget {
  ChatUserListPg({Key? key}) : super(key: key);

  @override
  _ChatUserListPgState createState() => _ChatUserListPgState();
}

class _ChatUserListPgState extends State<ChatUserListPg> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  void checkAuthentication() async {
    User? user = _auth.currentUser;
    if (user == null) {
      await _auth
          .signInAnonymously(); // Example: sign in anonymously for testing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return const Text("Error");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        print("Snapshot updated");

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(context, doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    // Check if 'email', 'username', and 'uid' are not null
    if (data.containsKey('email') &&
        data['email'] != null &&
        data.containsKey('username') &&
        data['username'] != null &&
        data.containsKey('uid') &&
        data['uid'] != null) {
      // Display users except the current logged-in user
      if (_auth.currentUser!.email != data['email']) {
        return ListTile(
          title: Text(data['username']),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoom(
                  receiverUserName: data['username'],
                  receiverUserId: data['uid'],
                ),
              ),
            );
          },
        );
      }
    }

    return Container();
  }
}
