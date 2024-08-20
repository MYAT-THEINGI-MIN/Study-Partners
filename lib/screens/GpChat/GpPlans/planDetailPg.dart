import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/GpPlans/planTaskCard.dart';

class PlanDetailPage extends StatelessWidget {
  final String planId;
  final String groupId;
  final String planName;
  final String username;
  final DateTime deadline;
  final int taskCount;
  final List<Map<String, dynamic>> tasks;
  final String description; // Added description parameter
  final String note; // Added note parameter

  PlanDetailPage({
    required this.planId,
    required this.groupId,
    required this.planName,
    required this.username,
    required this.deadline,
    required this.taskCount,
    required this.tasks,
    required this.description, // Added description parameter
    required this.note, // Added note parameter
  });

  Future<void> _deletePlan(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        int pointsToDeduct = taskCount;

        final planRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('plans')
            .doc(planId);
        final leaderboardRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('LeaderBoard')
            .doc(user.uid);

        DocumentSnapshot leaderboardSnapshot = await leaderboardRef.get();

        int currentPoints = leaderboardSnapshot.exists
            ? (leaderboardSnapshot.get('points') as int)
            : 0;
        int newPoints = currentPoints - pointsToDeduct;
        if (newPoints < 0) newPoints = 0;

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.delete(planRef);

          if (leaderboardSnapshot.exists) {
            transaction.update(leaderboardRef, {'points': newPoints});
          }
        });

        Navigator.pop(context);
      }
    } catch (e) {
      print('Error deleting plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting plan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedPlanDeadline = DateFormat('dd.MM.yyyy').format(deadline);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('plans')
                .doc(planId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData && snapshot.data != null) {
                final planData = snapshot.data!.data() as Map<String, dynamic>?;
                final planCreatorUid = planData?['uid'] as String?;
                final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

                if (planCreatorUid == currentUserUid) {
                  return IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deletePlan(context),
                  );
                }
              }

              return const SizedBox
                  .shrink(); // Return an empty widget if no delete icon should be shown
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Name: $planName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '$description',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Note: $note',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Created by: $username',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Deadline: $formattedPlanDeadline',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Number of Tasks: $taskCount',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tasks:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<User?>(
                future: _getCurrentUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    final currentUserUid = snapshot.data!.uid;

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];

                        final title = task['title'] is String
                            ? task['title']
                            : 'Untitled Task';

                        DateTime deadline;
                        try {
                          deadline = DateTime.parse(task['deadline']);
                        } catch (e) {
                          deadline = DateTime.now();
                        }

                        int completedCount = 0;
                        List<Map<String, dynamic>> completed = [];
                        if (task['completed'] is List) {
                          completed = (task['completed'] as List)
                              .where((e) => e is Map<String, dynamic>)
                              .map((e) => e as Map<String, dynamic>)
                              .toList();
                          completedCount = completed.length;
                        }

                        return PlanTaskCard(
                          title: title,
                          deadline: deadline,
                          completedCount: completedCount,
                          uid: currentUserUid,
                          currentUserUid: currentUserUid,
                          groupId: groupId,
                          planId: planId,
                          taskIndex: index,
                          completed: completed,
                        );
                      },
                    );
                  }

                  return const Center(child: Text('Error fetching user data'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<User?> _getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
}
