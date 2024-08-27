import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/GpChat/EditGroup/addPartner.dart';
import 'package:sp_test/screens/Planner/addTaskPg.dart';
import 'package:sp_test/screens/GpChat/GpPlans/TaskCompletionPage.dart';

class PlanTaskCard extends StatelessWidget {
  final String title;
  final DateTime deadline;
  final int completedCount;
  final String uid; // Task owner UID
  final String currentUserUid; // Currently logged-in user UID
  final String groupId;
  final String planId;
  final int taskIndex;
  final List<Map<String, dynamic>> completed; // Completed list
  final bool isOwner; // Whether the current user is the owner of the task

  PlanTaskCard({
    required this.title,
    required this.deadline,
    required this.completedCount,
    required this.uid,
    required this.currentUserUid,
    required this.groupId,
    required this.planId,
    required this.taskIndex,
    required this.completed,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    bool isCompletedByUser =
        completed.any((entry) => entry['uid'] == currentUserUid);

    String formattedTaskDeadline = DateFormat('dd.MM.yyyy').format(deadline);

    return Card(
      color: isCompletedByUser ? Colors.white : Colors.deepPurple.shade200,
      child: ListTile(
        title: Text(title),
        subtitle: Text(
            'Deadline: $formattedTaskDeadline\nCompleted: $completedCount'),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(context),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Add to Calendar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTaskPage(
                        uid: uid,
                        title: title,
                        deadline: deadline,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Mark as Completed'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsCompleted(context);
                },
              ),
              if (isOwner) // Show delete option only if the current user is the owner
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete Task'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTask(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _markAsCompleted(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    if (deadline.isAfter(startOfToday) ||
        deadline.isAtSameMomentAs(startOfToday)) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskCompletionPage(
            groupId: groupId,
            planId: planId,
            taskIndex: taskIndex,
          ),
        ),
      );
    } else {
      showTopSnackBar(
        context,
        'Task deadline has passed.',
      );
    }
  }

  void _deleteTask(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('plans')
          .doc(planId)
          .collection('tasks')
          .doc('$taskIndex')
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .update({
        'points': FieldValue.increment(-1),
      });

      showTopSnackBar(
        context,
        'Task deleted successfully and points updated.',
      );
    } catch (e) {
      showTopSnackBar(
        context,
        'Failed to delete task: $e',
      );
    }
  }
}
