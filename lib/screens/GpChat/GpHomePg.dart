import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/EditGroup/EditGp.dart';
import 'package:sp_test/screens/GpChat/FlashCard/FCpage.dart';
import 'package:sp_test/screens/GpChat/GpChatroom.dart';
import 'package:sp_test/screens/GpChat/GpLinkPage.dart';
import 'package:sp_test/screens/GpChat/GpPlans/GpPlans.dart';
import 'package:sp_test/screens/GpChat/LeaderBoard/LeaderBoard.dart';
import 'package:sp_test/screens/GpChat/MemberList.dart';
import 'package:sp_test/screens/GpChat/Notes/NotePg.dart';
import 'package:sp_test/screens/GpChat/QuizSection/showQuizPg.dart';
import 'package:sp_test/screens/GpChat/Study%20Timer/Timer.dart';
import 'package:sp_test/screens/GpChat/Study%20Timer/todayRecords.dart';
import 'package:sp_test/widgets/circularIcon.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

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
            Timestamp lastActivityTimestamp =
                groupData['lastActivityTimestamp'] ?? Timestamp.now();

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
                        const Icon(Icons.access_time, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Last Active:',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // Format the timestamp as needed
                          DateFormat.yMMMd()
                              .add_jm()
                              .format(lastActivityTimestamp.toDate()),
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
                        icon: Icons.link,
                        label: 'Links',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupLinksPage(
                                groupId: groupId,
                              ),
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
                        icon: Icons.groups_2_rounded,
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
                        // List of study records
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: AllStudyRecordsList(groupId: groupId),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _leaveGroup(BuildContext context) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      // Handle case where user is not logged in
      print('User is not logged in');
      return;
    }

    // Get group document
    final groupDocRef =
        FirebaseFirestore.instance.collection('groups').doc(groupId);
    final groupDoc = await groupDocRef.get();
    if (!groupDoc.exists) {
      print('Group does not exist');
      return;
    }

    final groupData = groupDoc.data()!;
    final adminId = groupData['adminId'] as String;
    final members = List<String>.from(groupData['members'] as List<dynamic>);

    if (currentUserUid == adminId) {
      TopSnackBarWiidget(context, 'Admin cannot leave the group');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Leave Group"),
          content: const Text("Are you sure you want to leave this group?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Leave"),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // Remove the user from the members array in the group document
                  await groupDocRef.update({
                    'members': FieldValue.arrayRemove([currentUserUid]),
                  });

                  // Remove the user's data from relevant collections
                  final collections = [
                    'LeaderBoard',
                    'Flashcards',
                    'Quiz',
                    'StudyRecord',
                    'notes',
                    'plans'
                  ];

                  for (var collection in collections) {
                    final docs = await groupDocRef
                        .collection(collection)
                        .where('userId', isEqualTo: currentUserUid)
                        .get();
                    for (var doc in docs.docs) {
                      await doc.reference.delete();
                    }
                  }

                  // Optionally: Handle additional logic for leaving the group
                  // e.g., showing a success message or navigating to another page
                  Navigator.pop(context); // Go back to the previous screen
                } catch (e) {
                  print('Error leaving group: $e');
                  // Handle errors appropriately
                }
              },
            ),
          ],
        );
      },
    );
  }
}
