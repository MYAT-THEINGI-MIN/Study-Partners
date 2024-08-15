import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
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
                ..sort((a, b) =>
                    (b.get('points') as int).compareTo(a.get('points') as int));

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

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$points points'),
                                SizedBox(width: 8),
                                medalIcon,
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
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

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Icon(Icons.person)
                                : null,
                          ),
                          title: Text(name),
                          trailing: Text('$points points'),
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
        return Icon(Icons.star, color: Colors.amber); // Gold medal
      case 1:
        return Icon(Icons.star, color: Colors.grey); // Silver medal
      case 2:
        return Icon(Icons.star, color: Colors.brown); // Bronze medal
      default:
        return SizedBox.shrink();
    }
  }
}
