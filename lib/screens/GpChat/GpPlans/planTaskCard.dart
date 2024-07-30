import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/GpPlans/TaskCompletionPage.dart';
import 'package:sp_test/screens/Planner/addTaskPg.dart';

class PlanTaskCard extends StatelessWidget {
  final String title;
  final DateTime deadline;
  final List<String> completed;
  final String uid;
  final String groupId; // Added groupId
  final String planId; // Added planId
  final int taskIndex; // Added taskIndex to locate the task in the array

  PlanTaskCard({
    required this.title,
    required this.deadline,
    required this.completed,
    required this.uid,
    required this.groupId, // Added groupId
    required this.planId, // Added planId
    required this.taskIndex, // Added taskIndex
  });

  @override
  Widget build(BuildContext context) {
    // Format the deadline date for the task to 'day.month.year'
    String formattedTaskDeadline = DateFormat('dd.MM.yyyy').format(deadline);

    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
            'Deadline: $formattedTaskDeadline\nCompleted: ${completed.length}'),
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
