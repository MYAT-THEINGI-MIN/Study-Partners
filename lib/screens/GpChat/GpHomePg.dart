import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/GpChat/EditGp.dart'; // Make sure this import path is correct
import 'package:sp_test/screens/GpChat/FlashCard/FCpage.dart';
import 'package:sp_test/screens/GpChat/GpChatroom.dart';
import 'package:sp_test/screens/GpChat/GpPlans.dart';
import 'package:sp_test/screens/GpChat/LeaderBoard.dart';
import 'package:sp_test/screens/GpChat/MemberList.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ensure to import FirebaseAuth

class GroupHomePage extends StatelessWidget {
  final String groupId;

  GroupHomePage({required this.groupId});

  Future<void> _leaveGroup(BuildContext context) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayRemove([currentUserId])
      });
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => EditGroupPage(
                      groupId: groupId,
                      groupName: '',
                      groupSubject: '',
                      gpProfileUrl: '',
                    ),
                  ),
                );
              } else if (value == 'Leave Group') {
                _leaveGroup(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Edit', 'Leave Group'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: Text('Error loading group data.'));
          }

          var groupData = snapshot.data!.data() as Map<String, dynamic>;
          String groupName = groupData['groupName'];
          String subject = groupData['subject'];
          String profileUrl = groupData['profileUrl'];
          String adminId = groupData['adminId'];

          return Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(profileUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          subject,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.task_rounded),
                        title: const Text('Group Plans'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GpPlans(
                                  groupId: groupId), // Pass groupId here
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.book_rounded),
                        title: const Text('Notes'),
                        onTap: () {
                          // Add your navigation or functionality here
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.quiz_rounded),
                        title: const Text('Quiz'),
                        onTap: () {
                          // Add your navigation or functionality here
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.lightbulb),
                        title: const Text('Flash Card'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FlashcardsPage(
                                groupId: groupId,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.leaderboard),
                        title: const Text('LeaderBoard'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaderboardPage(
                                groupId: groupId,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.group),
                        title: const Text('Members'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemberList(
                                groupId: groupId,
                                isAdmin: adminId ==
                                    FirebaseAuth.instance.currentUser?.uid,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Icon(Icons.error);
          }

          var groupData = snapshot.data!.data() as Map<String, dynamic>;
          String groupName = groupData['groupName'];
          String profileUrl = groupData['profileUrl'];
          String adminId = groupData['adminId'];

          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GpChatRoom(
                    groupId: groupId,
                    groupName: groupName,
                    gpProfileUrl: profileUrl,
                    adminId: adminId,
                  ),
                ),
              );
            },
            child: const Icon(Icons.chat),
          );
        },
      ),
    );
  }
}
