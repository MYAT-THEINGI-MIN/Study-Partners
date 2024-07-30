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

  PlanDetailPage({
    required this.planId,
    required this.groupId,
    required this.planName,
    required this.username,
    required this.deadline,
    required this.taskCount,
    required this.tasks,
  });

  Future<void> _deletePlan(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('plans')
            .doc(planId)
            .delete();
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting plan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the deadline date for the plan to 'day.month.year'
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

              return SizedBox
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
                        return PlanTaskCard(
                          title: task['title'],
                          deadline: DateTime.parse(task['deadline']),
                          completed: List<String>.from(task['completed']),
                          uid: currentUserUid, // Pass the current user UID
                          groupId: groupId, // Pass groupId
                          planId: planId, // Pass planId
                          taskIndex: index, // Pass taskIndex
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
