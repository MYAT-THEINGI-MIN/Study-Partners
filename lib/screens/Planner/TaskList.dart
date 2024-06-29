import 'package:flutter/material.dart';

class TaskListWidget extends StatelessWidget {
  final String uid;
  final List<dynamic> events;

  const TaskListWidget({Key? key, required this.uid, required this.events})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> task = events[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          color: task.containsKey('color') ? Color(task['color']) : Colors.blue,
          child: ListTile(
            title: Text(task['title'] ?? 'No Title'),
            subtitle: Text(task['note'] ?? 'No Note'),
            trailing: Text(task['time'] ?? 'No Time'),
          ),
        );
      },
    );
  }
}
