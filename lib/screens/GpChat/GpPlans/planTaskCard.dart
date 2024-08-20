import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/GpPlans/TaskCompletionPage.dart';
import 'package:sp_test/screens/Planner/addTaskPg.dart';

class PlanTaskCard extends StatelessWidget {
  final String title;
  final DateTime deadline;
  final int completedCount;
  final String uid;
  final String currentUserUid; // The UID of the currently logged-in user
  final String groupId;
  final String planId;
  final int taskIndex;
  final List<Map<String, dynamic>> completed; // Handle completed data structure

  PlanTaskCard({
    required this.title,
    required this.deadline,
    required this.completedCount,
    required this.uid,
    required this.currentUserUid, // Pass the current user's UID
    required this.groupId,
    required this.planId,
    required this.taskIndex,
    required this.completed, // Handle the completed array properly
  });

  @override
  Widget build(BuildContext context) {
    // Check if the current user UID is in the completed list
    bool isCompletedByUser =
        completed.any((entry) => entry['uid'] == currentUserUid);

    // Format the deadline date for the task to 'day.month.year'
    String formattedTaskDeadline = DateFormat('dd.MM.yyyy').format(deadline);

    return Card(
      color: isCompletedByUser
          ? Colors.white
          : Colors
              .deepPurple.shade200, // Change color based on completion status
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
                  Navigator.pop(context); // Close the bottom sheet
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
                leading: const Icon(Icons.check_circle),
                title: const Text('Complete Task'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
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
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
