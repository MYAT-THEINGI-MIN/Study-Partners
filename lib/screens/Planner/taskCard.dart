import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String id;
  final String title;
  final String note;
  final String? time; // Accept time as nullable
  final int color; // Accept color as int
  final Function(String) onDelete;
  final Function(String) onDone;
  final Function(String) onEdit;
  final Function(String) onUndone; // Callback for marking as undone

  const TaskCard({
    required this.id,
    required this.title,
    required this.note,
    this.time, // Accept time as nullable
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
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    final iconColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return Row(
      children: [
        // Display the time outside the card, or "......." if time is null
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            time ?? '.......',
            style: TextStyle(color: textColor),
          ),
        ),
        // Display the card with the task details
        Expanded(
          child: Card(
            color: displayColor,
            child: ListTile(
              title: Text(
                title,
                style: TextStyle(color: Colors.black),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note,
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.more_vert, color: Colors.black),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete Task',
                                style: TextStyle(color: Colors.red)),
                            onTap: () {
                              Navigator.pop(context);
                              onDelete(id);
                            },
                          ),
                          if (!isDone)
                            ListTile(
                              leading: Icon(Icons.done, color: iconColor),
                              title: Text('Mark as Done',
                                  style: TextStyle(color: iconColor)),
                              onTap: () {
                                Navigator.pop(context);
                                onDone(id);
                              },
                            ),
                          if (isDone)
                            ListTile(
                              leading: Icon(Icons.undo, color: iconColor),
                              title: Text('Mark as Undone',
                                  style: TextStyle(color: iconColor)),
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
          ),
        ),
      ],
    );
  }
}
