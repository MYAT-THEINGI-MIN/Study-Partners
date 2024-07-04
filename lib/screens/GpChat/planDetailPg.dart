import 'package:flutter/material.dart';

class PlanDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final DateTime deadline;

  PlanDetailPage({
    required this.title,
    required this.description,
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Detail'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 8),
            Text(description),
            SizedBox(height: 8),
            Text(
              'Deadline: ${deadline.toString()}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}
