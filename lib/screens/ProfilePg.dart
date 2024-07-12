import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/EditProfilePg.dart';

class ProfilePg extends StatefulWidget {
  const ProfilePg({Key? key}) : super(key: key);

  @override
  _ProfilePgState createState() => _ProfilePgState();
}

class _ProfilePgState extends State<ProfilePg> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> _handleRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
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

              // Determine text color based on theme brightness
              Color textColor = Theme.of(context).brightness == Brightness.light
                  ? Colors.black87 // Soft black for light theme
                  : Color.fromARGB(
                      255, 244, 244, 244); // Light color for dark theme

              return ListView(
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
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Email: ${userData['email']}',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Status: ${userData['status'] ?? "No status set"}',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  SizedBox(height: 8),
                  if (subjects != null && subjects.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: subjects.split(',').map((subject) {
                        return Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple
                                .shade200, // Set to a deep purple shade
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            subject.trim(),
                            style: TextStyle(fontSize: 16, color: textColor),
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
                          builder: (context) =>
                              EditProfilePg(userData: userData),
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
      ),
    );
  }
}
