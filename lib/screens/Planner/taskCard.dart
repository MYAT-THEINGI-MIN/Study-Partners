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
  final Function(String) onUndone; // Callback for marking as undone

  const TaskCard({
    required this.id,
    required this.title,
    required this.note,
    required this.time,
    required this.color, // Accept color as int
    required this.onDelete,
    required this.onDone,
    required this.onEdit,
    required this.onUndone, // Callback for marking as undone
  });

  @override
  Widget build(BuildContext context) {
    final isDone = color == const Color.fromARGB(255, 222, 222, 222).value;
    print('Task ID: $id');
    print('Task Color: $color');
    print('Is Done: $isDone');

    final displayColor =
        isDone ? const Color.fromARGB(255, 222, 222, 222) : Color(color);
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
                    if (!isDone)
                      ListTile(
                        leading: Icon(Icons.done, color: textColor),
                        title: Text('Mark as Done',
                            style: TextStyle(color: textColor)),
                        onTap: () {
                          Navigator.pop(context);
                          onDone(id);
                        },
                      ),
                    if (isDone)
                      ListTile(
                        leading: Icon(Icons.undo, color: textColor),
                        title: Text('Mark as Undone',
                            style: TextStyle(color: textColor)),
                        onTap: () {
                          Navigator.pop(context);
                          onUndone(id);
                        },
                      ),
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
