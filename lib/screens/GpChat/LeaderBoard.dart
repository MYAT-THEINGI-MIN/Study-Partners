import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _resetPoints(BuildContext context) async {
    final confirmReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Reset'),
        content: Text('Are you sure you want to reset all points to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmReset ?? false) {
      // Reset all points to 0
      final groupCollection = FirebaseFirestore.instance.collection('groups');
      final leaderboardCollection =
          groupCollection.doc(groupId).collection('LeaderBoard');

      final documents = await leaderboardCollection.get();

      for (var doc in documents.docs) {
        await doc.reference.update({'points': 0});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Points have been reset.')),
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
          FutureBuilder<String>(
            future: _fetchAdminId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              }

              if (snapshot.hasError) {
                return SizedBox.shrink();
              }

              final adminId = snapshot.data;

              // Check if the current user is the admin
              final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
              if (adminId == currentUserUid) {
                return IconButton(
                  icon: Icon(Icons.restore),
                  onPressed: () => _resetPoints(context),
                );
              }

              return SizedBox.shrink();
            },
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
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No leaderboard data available.'));
          }

          final documents = snapshot.data!.docs;
          final userIds = documents.map((doc) => doc.id).toSet().toList();

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: _fetchUserDetails(userIds),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }

              if (!userSnapshot.hasData) {
                return Center(child: Text('No user details available.'));
              }

              final userDetails = userSnapshot.data!;
              final sortedDocuments = documents
                ..sort((a, b) {
                  final pointsA = a.get('points') as int;
                  final pointsB = b.get('points') as int;

                  if (pointsA == pointsB) {
                    // Break ties by user ID
                    return a.id.compareTo(b.id);
                  }
                  return pointsB.compareTo(pointsA);
                });

              return Column(
                children: [
                  // Top 3 leaderboard
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: List.generate(
                        3,
                        (index) {
                          if (index >= sortedDocuments.length)
                            return SizedBox.shrink();
                          final doc = sortedDocuments[index];
                          final userId = doc.id;
                          final points = doc.get('points') as int;
                          final name =
                              userDetails[userId]?['username'] ?? 'Unknown';
                          final profileImageUrl =
                              userDetails[userId]?['profileImageUrl'] ?? '';
                          final medalIcon = _getMedalIcon(index);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Ranking number
                                Container(
                                  alignment: Alignment.center,
                                  width: 40,
                                  child: Text(
                                    '${index + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: index == 0
                                              ? Colors.amber
                                              : index == 1
                                                  ? Colors.grey
                                                  : Colors.brown,
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          profileImageUrl.isNotEmpty
                                              ? NetworkImage(profileImageUrl)
                                              : null,
                                      child: profileImageUrl.isEmpty
                                          ? Icon(Icons.person,
                                              color: Colors.grey)
                                          : null,
                                    ),
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$points points',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        medalIcon,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Ranking number
                              Container(
                                alignment: Alignment.center,
                                width: 40,
                                child: Text(
                                  '${index + 4}', // Ranking starts from 4 for the rest
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundImage: profileImageUrl.isNotEmpty
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child: profileImageUrl.isEmpty
                                        ? Icon(Icons.person, color: Colors.grey)
                                        : null,
                                  ),
                                  title: Text(name),
                                  trailing: Text('$points points'),
                                ),
                              ),
                            ],
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
        return Icon(Icons.star, color: Colors.amber, size: 24); // Gold medal
      case 1:
        return Icon(Icons.star, color: Colors.grey, size: 24); // Silver medal
      case 2:
        return Icon(Icons.star, color: Colors.brown, size: 24); // Bronze medal
      default:
        return SizedBox.shrink();
    }
  }
}
