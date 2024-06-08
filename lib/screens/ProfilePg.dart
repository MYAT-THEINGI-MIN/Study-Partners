import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/EditProfilePg.dart';

class ProfilePg extends StatelessWidget {
  const ProfilePg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('User data not found'));
            }

            Map<String, dynamic> userData =
                snapshot.data!.data() as Map<String, dynamic>;
            String? subjects = userData['subjects'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      userData['profilePicUrl'] ??
                          'https://example.com/default.jpg',
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Username: ${userData['username']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Email: ${userData['email']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Status: ${userData['status'] ?? "No status set"}',
                  style: TextStyle(fontSize: 16),
                ), // Display status
                SizedBox(height: 8),
                if (subjects != null && subjects.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subjects.split(',').map((subject) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          subject.trim(),
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePg(userData: userData),
                      ),
                    );
                  },
                  child: Text('Edit Profile'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
