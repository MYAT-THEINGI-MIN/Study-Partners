import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/GpPlans/planDetailPg.dart';

class PlanCard extends StatelessWidget {
  final String planId;
  final String groupId;
  final String planName;
  final String username;
  final DateTime deadline;
  final int taskCount;
  final List<Map<String, dynamic>> tasks;
  final String description; // Add this
  final String note; // Add this

  PlanCard({
    required this.planId,
    required this.groupId,
    required this.planName,
    required this.username,
    required this.deadline,
    required this.taskCount,
    required this.tasks,
    required this.description, // Add this
    required this.note, // Add this
  });

  @override
  Widget build(BuildContext context) {
    String formattedDeadline = DateFormat('dd.MM.yyyy').format(deadline);

    return Card(
      child: ListTile(
        title: Text(planName),
        subtitle: Text(
          'Created by: $username\nDeadline: $formattedDeadline\nTasks: $taskCount',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanDetailPage(
                planId: planId,
                groupId: groupId,
                planName: planName,
                username: username,
                deadline: deadline,
                taskCount: taskCount,
                tasks: tasks,
                description: description, // Add this
                note: note, // Add this
              ),
            ),
          );
        },
      ),
    );
  }
}
