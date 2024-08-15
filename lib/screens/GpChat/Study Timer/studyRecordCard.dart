import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudyRecordCard extends StatelessWidget {
  final String recordId;
  final String groupId;
  final String formattedDate;
  final int totalTime;
  final int totalBreaks;
  final int breakTime;

  const StudyRecordCard({
    Key? key,
    required this.recordId,
    required this.groupId,
    required this.formattedDate,
    required this.totalTime,
    required this.totalBreaks,
    required this.breakTime,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return userDoc.data() ?? {};
      } catch (e) {
        print('Error fetching user data: $e');
        return {};
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> _fetchRecordData() async {
    try {
      final recordDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('StudyRecord')
          .doc(recordId)
          .get();
      return recordDoc.data() ?? {};
    } catch (e) {
      print('Error fetching record data: $e');
      return {};
    }
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No data available.'));
        }

        final user = data['user'] as Map<String, dynamic>?;
        final record = data['record'] as Map<String, dynamic>?;

        if (user == null || record == null) {
          return const Center(child: Text('User or record data is missing.'));
        }

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
                      backgroundImage: (user['profileImageUrl'] != null &&
                              user['profileImageUrl'].isNotEmpty)
                          ? NetworkImage(user['profileImageUrl'])
                          : const AssetImage('assets/default_profile.png')
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
