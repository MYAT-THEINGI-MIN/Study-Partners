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
import 'package:sp_test/screens/GpChat/QuizSection/showQuizPg.dart';
import 'package:sp_test/screens/GpChat/Study%20Timer/Timer.dart';
import 'package:sp_test/screens/GpChat/Study%20Timer/todayRecords.dart';
import 'package:sp_test/widgets/circularIcon.dart';

class GroupHomePage extends StatelessWidget {
  final String groupId;

  GroupHomePage({required this.groupId});

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
                  padding: const EdgeInsets.only(left: 20),
                  width: 400,
                  child: Container(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
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
                const SizedBox(height: 15),
                const Divider(thickness: 2, height: 30),

                // First row of icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircularIcon(
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
                      CircularIcon(
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
                      CircularIcon(
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
                      CircularIcon(
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

                // Second row of icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircularIcon(
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
                      CircularIcon(
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
                      CircularIcon(
                        icon: Icons.chat_rounded,
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
                                subject: subject,
                              ),
                            ),
                          );
                        },
                      ),
                      CircularIcon(
                        icon: Icons.add_circle,
                        label: 'Member',
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

                const SizedBox(height: 15),
                const Divider(thickness: 2, height: 30),

                // List of study records
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          " Today's Study Records",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: MediaQuery.of(context).size.height *
                              0.7, // Adjust height as needed
                          child: AllStudyRecordsList(groupId: groupId),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  void _leaveGroup(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayRemove([userId]),
      });
      Navigator.pop(context);
    }
  }
}
