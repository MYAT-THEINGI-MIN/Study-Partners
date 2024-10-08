import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/LeaderBoard/DetectActivity.dart';
import 'package:sp_test/screens/GpChat/LeaderBoard/pointSystem.dart';

class LeaderboardPage extends StatelessWidget {
  final String groupId;

  LeaderboardPage({required this.groupId});

  Future<Map<String, Map<String, dynamic>>> _fetchUserDetails(
      List<String> userIds) async {
    final userDetails = <String, Map<String, dynamic>>{};
    final userCollection = FirebaseFirestore.instance.collection('users');

    for (String userId in userIds) {
      final userDoc = await userCollection.doc(userId).get();
      if (userDoc.exists) {
        userDetails[userId] = userDoc.data()!;
      }
    }

    return userDetails;
  }

  Future<String> _fetchAdminId() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();
    return groupDoc.get('adminId') as String;
  }

  Future<void> _showOptionsMenu(BuildContext context) async {
    final adminId = await _fetchAdminId();
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    if (adminId == currentUserUid) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.system_update_alt),
                title: const Text('Reset Points'),
                onTap: () {
                  Navigator.of(context).pop();
                  _resetPoints(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Point System'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PointSystemPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Member Activity'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MemberActivityPage(
                          groupId:
                              groupId), // Pass groupId to the MemberActivityPage
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You do not have permission to reset points.')),
      );
    }
  }

  Future<void> _resetPoints(BuildContext context) async {
    final confirmReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text('Are you sure you want to reset all points to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmReset ?? false) {
      final groupCollection = FirebaseFirestore.instance.collection('groups');
      final leaderboardCollection =
          groupCollection.doc(groupId).collection('LeaderBoard');

      final documents = await leaderboardCollection.get();

      for (var doc in documents.docs) {
        await doc.reference.update({'points': 0});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Points have been reset.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.deepPurple.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('LeaderBoard')
            .orderBy('points', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No leaderboard data available.'));
          }

          final documents = snapshot.data!.docs;
          final userIds = documents.map((doc) => doc.id).toSet().toList();

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: _fetchUserDetails(userIds),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }

              if (!userSnapshot.hasData) {
                return const Center(child: Text('No user details available.'));
              }

              final userDetails = userSnapshot.data!;
              final sortedDocuments = documents
                ..sort((a, b) {
                  final pointsA = a.get('points') as int;
                  final pointsB = b.get('points') as int;
                  return pointsB.compareTo(pointsA);
                });

              return Column(
                children: [
                  // Top 3 leaderboard
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(3, (index) {
                        if (index >= sortedDocuments.length)
                          return const SizedBox(
                            height: 20,
                          );
                        final doc = sortedDocuments[index];
                        final userId = doc.id;
                        final points = doc.get('points') as int;
                        final name =
                            userDetails[userId]?['username'] ?? 'Unknown';
                        final profileImageUrl =
                            userDetails[userId]?['profileImageUrl'] ?? '';
                        final medalIcon = _getMedalIcon(index);

                        return Column(
                          children: [
                            // Medal icon below the profile
                            medalIcon,
                            // Profile image
                            CircleAvatar(
                              radius: index == 0 ? 46 : (index == 1 ? 40 : 30),
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 40, color: Colors.grey)
                                  : null,
                            ),

                            // Name and points below the profile
                            Text(
                              name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '$points points',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  // All users below top 3
                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedDocuments.length > 3
                          ? sortedDocuments.length - 3
                          : 0,
                      itemBuilder: (context, index) {
                        final doc = sortedDocuments[index + 3];
                        final userId = doc.id;
                        final points = doc.get('points') as int;
                        final name =
                            userDetails[userId]?['username'] ?? 'Unknown';
                        final profileImageUrl =
                            userDetails[userId]?['profileImageUrl'] ?? '';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${index + 4}', // Position number for ranks below top 3
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  backgroundImage: profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  child: profileImageUrl.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.grey)
                                      : null,
                                ),
                              ],
                            ),
                            title: Text(name),
                            trailing: Text(
                              '$points points',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _getMedalIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.looks_one, color: Colors.amber, size: 30);
      case 1:
        return const Icon(Icons.looks_two, color: Colors.grey, size: 30);
      case 2:
        return const Icon(Icons.looks_3, color: Colors.brown, size: 30);
      default:
        return const SizedBox.shrink();
    }
  }
}
