import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShareTasksSheet extends StatelessWidget {
  final BuildContext parentContext;
  final List<DocumentSnapshot> groups;
  final List<Map<String, dynamic>> tasks;
  final String uid;
  final String planName;
  final String note;

  ShareTasksSheet({
    required this.parentContext,
    required this.groups,
    required this.tasks,
    required this.uid,
    required this.planName,
    required this.note,
  });

  Future<String> _getUsername(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc['username'] ?? 'Unknown User';
  }

  Future<void> _updatePoints(String groupId) async {
    final leaderboardRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('LeaderBoard')
        .doc(uid);

    final userDoc = await leaderboardRef.get();
    int currentPoints = 0;

    if (userDoc.exists) {
      currentPoints = userDoc['points'] ?? 0;
    }

    await leaderboardRef.set({
      'name': await _getUsername(uid),
      'points': currentPoints + tasks.length,
    }, SetOptions(merge: true));
  }

  Future<void> _shareTasks(String groupId) async {
    if (tasks.isEmpty || planName.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
            content: Text('Please complete all fields and select tasks')),
      );
      return;
    }

    final username = await _getUsername(uid);
    final planRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('plans')
        .doc();

    await planRef.set({
      'planName': planName,
      'uid': uid,
      'username': username,
      'note': note,
      'tasks': tasks
          .map((task) => {
                'title': task['title'],
                'deadline': task['date'],
                'completed': [], // Initialize with empty completed list
              })
          .toList(),
    });

    await _updatePoints(groupId);

    ScaffoldMessenger.of(parentContext).showSnackBar(
      const SnackBar(content: Text('Tasks shared and points awarded!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select a Group to Share Tasks',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
          ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  title: Text(group['groupName'] ?? 'Unnamed Group'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareTasks(group.id);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
