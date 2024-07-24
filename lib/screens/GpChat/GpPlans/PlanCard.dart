import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  final String planId;
  final String groupId;
  final String planName;
  final String username;
  final DateTime deadline;
  final int taskCount;

  PlanCard({
    required this.planId,
    required this.groupId,
    required this.planName,
    required this.username,
    required this.deadline,
    required this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(planName),
        subtitle: Text(
            'Created by: $username\nDeadline: ${deadline.toLocal().toString().split(' ')[0]}\nTasks: $taskCount'),
      ),
    );
  }
}
