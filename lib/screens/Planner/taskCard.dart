import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String id;
  final String title;
  final String note;
  final String time;
  final int color; // Accept color as int
  final Function(String) onDelete;
  final Function(String) onDone;
  final Function(String) onEdit;

  const TaskCard({
    required this.id,
    required this.title,
    required this.note,
    required this.time,
    required this.color, // Accept color as int
    required this.onDelete,
    required this.onDone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDone =
        color == Colors.grey.value; // Check if the task is marked as done
    final displayColor = isDone ? Colors.grey : Color(color);
    final theme = Theme.of(context);
    final textColor =
        theme.brightness == Brightness.dark ? Colors.deepPurple : Colors.black;

    return Card(
      color: displayColor,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note,
              style: TextStyle(color: textColor),
            ),
            Text(
              time,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: textColor),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.delete, color: textColor),
                      title: Text('Delete Task',
                          style: TextStyle(color: textColor)),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete(id);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.done, color: textColor),
                      title: Text('Mark as Done',
                          style: TextStyle(color: textColor)),
                      onTap: () {
                        Navigator.pop(context);
                        onDone(id);
                      },
                    ),
                    // Uncomment and adjust the following lines for editing task
                    // ListTile(
                    //   leading: Icon(Icons.edit, color: textColor),
                    //   title: Text('Edit Task', style: TextStyle(color: textColor)),
                    //   onTap: () {
                    //     Navigator.pop(context); // Close the bottom sheet
                    //     onEdit(id); // Call onEdit function with task ID

                    //     // Navigate to EditTaskPage
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => EditTaskPage(
                    //             uid: 'current_user_uid', taskId: id),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
