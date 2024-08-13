import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyRecordCard extends StatelessWidget {
  final String recordId; // ID of the study record
  final String groupId; // ID of the group for fetching user details

  StudyRecordCard({
    required this.recordId,
    required this.groupId,
    required formattedDate,
    required totalTime,
    required totalBreaks,
    required breakTime,
  });

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetching user details from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc.data()!;
    }
    return {};
  }

  Future<Map<String, dynamic>> _fetchRecordData() async {
    final recordDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('StudyRecord')
        .doc(recordId)
        .get();
    return recordDoc.data()!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _fetchUserData(),
        _fetchRecordData(),
      ]).then((results) {
        return {
          'user': results[0],
          'record': results[1],
        };
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final user = data['user']!;
        final record = data['record']!;

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: user['profileUrl'] != null
                          ? NetworkImage(user['profileUrl'])
                          : AssetImage('assets/default_profile.png')
                              as ImageProvider,
                      radius: 30,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      user['username'] ?? 'Unknown User',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Time: ${_formatTime(record['totalTime'] ?? 0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Total Breaks: ${record['totalBreaks'] ?? 0}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Break Time: ${_formatTime(record['breakTime'] ?? 0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Date: ${record['formattedDate'] ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int timeInSeconds) {
    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
