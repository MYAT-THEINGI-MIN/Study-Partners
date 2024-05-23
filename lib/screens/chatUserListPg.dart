import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/screens/chatRoom.dart';
import 'package:sp_test/Service/chatService.dart'; // Import your Chatservice file

class ChatUserListPg extends StatefulWidget {
  ChatUserListPg({Key? key}) : super(key: key);

  @override
  _ChatUserListPgState createState() => _ChatUserListPgState();
}

class _ChatUserListPgState extends State<ChatUserListPg> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _userStream;
  final Chatservice _chatService = Chatservice(); // Initialize Chatservice

  @override
  void initState() {
    super.initState();
    checkAuthentication();
    _userStream = FirebaseFirestore.instance.collection('users').snapshots();
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
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return Text("Error");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

            if (data.containsKey('email') &&
                data.containsKey('username') &&
                data.containsKey('uid')) {
              String username = data['username'];
              String uid = data['uid'];

              if (_auth.currentUser!.email != data['email']) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(username),
                      subtitle: FutureBuilder<String>(
                        future: _getRecentMessage(uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text('Loading...');
                          }
                          return Text(snapshot.data ?? '');
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoom(
                              receiverUserName: username,
                              receiverUserId: uid,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: Colors.purple,
                      thickness: 1,
                      height: 0,
                    ),
                  ],
                );
              }
            }

            return Container();
          },
        );
      },
    );
  }

  Future<String> _getRecentMessage(String userId) async {
    // Fetch recent message using Chatservice
    // Replace this with your actual call to Chatservice
    Stream<QuerySnapshot> messageStream =
        _chatService.getMessages(_auth.currentUser!.uid, userId);
    List<DocumentSnapshot> messageDocs =
        await messageStream.first.then((snapshot) => snapshot.docs);

    if (messageDocs.isNotEmpty) {
      // Get the most recent message
      DocumentSnapshot recentMessage = messageDocs.last;
      Map<String, dynamic> messageData =
          recentMessage.data()! as Map<String, dynamic>;
      return messageData['message'] ?? '';
    } else {
      return '';
    }
  }
}
