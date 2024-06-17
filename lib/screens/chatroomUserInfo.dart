import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatroomUserInfo extends StatelessWidget {
  final String userId;

  ChatroomUserInfo({required this.userId});

  void blockUser(BuildContext context, String blockedUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Add current user's UID and blocked user's UID to Firestore
      await FirebaseFirestore.instance
          .collection('blocked_list')
          .doc(currentUserId)
          .set({
        'blockedUserId': blockedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show a snackbar or dialog to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User blocked successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle errors
      print('Error blocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to block user. Please try again later.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

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
                // Block Button
                SizedBox(
                  width: double.infinity, // Full width button
                  child: ElevatedButton(
                    onPressed: () {
                      blockUser(context, userId); // Call block user function
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 227, 87, 77)),
                    child: Text('Block User',
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
