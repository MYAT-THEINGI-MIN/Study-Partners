import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/EditGroup/EditGp.dart';
import 'package:sp_test/screens/GpChat/FlashCard/FCpage.dart';
import 'package:sp_test/screens/GpChat/GpChatroom.dart';
import 'package:sp_test/screens/GpChat/GpPlans/GpPlans.dart';
import 'package:sp_test/screens/GpChat/LeaderBoard.dart';
import 'package:sp_test/screens/GpChat/MemberList.dart';
import 'package:sp_test/screens/GpChat/Notes/NotePg.dart';
import 'package:sp_test/screens/GpChat/QuizSection/createQuiz.dart';
import 'package:sp_test/screens/GpChat/QuizSection/showQuizPg.dart';
import 'package:sp_test/screens/GpChat/Study%20Timer/Timer.dart';

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
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('groups')
              .doc(groupId)
              .get(),
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
            String leaderNote = groupData['leaderNote'];
            int studyHardPoints = groupData['StudyHardPoint'] ?? 0;

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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            subject,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 400,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.deepPurple.shade400,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leader Note',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        leaderNote,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.only(left: 20),
                  width: 400,
                  child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.credit_score,
                            color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Group StudyHard Score:',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          studyHardPoints.toString(),
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                    height:
                        15), // Increased padding to match the space below the first row
                const Divider(thickness: 2, height: 30),

                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircularIcon(
                        context,
                        icon: Icons.task_rounded,
                        label: 'Plans',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GpPlans(groupId: groupId),
                            ),
                          );
                        },
                      ),
                      _buildCircularIcon(
                        context,
                        icon: Icons.book_rounded,
                        label: 'Notes',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotePage(groupId: groupId),
                            ),
                          );
                        },
                      ),
                      _buildCircularIcon(
                        context,
                        icon: Icons.quiz_rounded,
                        label: 'Quiz',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ShowQuizPage(groupId: groupId),
                            ),
                          );
                        },
                      ),
                      _buildCircularIcon(
                        context,
                        icon: Icons.lightbulb,
                        label: 'FlashCard',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FlashcardsPage(groupId: groupId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                const Divider(thickness: 2, height: 30),
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircularIcon(
                        context,
                        icon: Icons.timer,
                        label: 'Timer',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TimerPage(groupId: groupId),
                            ),
                          );
                        },
                      ),
                      _buildCircularIcon(
                        context,
                        icon: Icons.leaderboard,
                        label: 'LeadBoard',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LeaderboardPage(groupId: groupId),
                            ),
                          );
                        },
                      ),
                      _buildCircularIcon(
                        context,
                        icon: Icons.group,
                        label: 'Members',
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
                      _buildCircularIcon(
                        context,
                        icon: Icons.chat_bubble,
                        label: 'Chat',
                        onTap: () {
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 2, height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircularIcon(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
