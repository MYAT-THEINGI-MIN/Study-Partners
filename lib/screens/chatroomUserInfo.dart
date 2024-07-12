import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatroom.dart'; // Import the ChatRoom screen

class ChatroomUserInfo extends StatelessWidget {
  final String userId;

  ChatroomUserInfo({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Info'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return Center(child: Text('No user data found.'));
          }

          var userData = snapshot.data!.data()!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context)
                      .size
                      .width, // Set width to screen width
                  height: MediaQuery.of(context).size.width *
                      0.8, // Aspect ratio, adjust as needed
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    image: DecorationImage(
                      image: userData['profileImageUrl'] != null
                          ? NetworkImage(userData['profileImageUrl'])
                          : AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Username: ${userData['username']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Subjects: ${userData['subjects'] ?? 'Not specified'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Status: ${userData['status'] ?? 'Not specified'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                // Chat Button
                SizedBox(
                  width: double.infinity, // Full width button
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoom(
                            receiverUserName: userData['username'],
                            receiverUserId: userId,
                          ),
                        ),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text('Chat',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
