import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/planDetailPg.dart';

class PlanCard extends StatelessWidget {
  final String planId;
  final String groupId;
  final String title;
  final String description;
  final String creatorName; // Named parameter for creator's name
  final DateTime deadline;

  PlanCard({
    required this.planId,
    required this.groupId,
    required this.title,
    required this.description,
    required this.creatorName, // Named parameter for creator's name
    required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    // Format the deadline date
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    final String formattedDeadline = formatter.format(deadline);

    return GestureDetector(
      onTap: () {
        // Navigate to the plan detail page here
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanDetailPage(
              planId: planId,
              groupId: groupId,
              title: title,
              description: description,
              deadline: deadline,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          contentPadding: EdgeInsets.all(16.0),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(description),
              SizedBox(height: 8),
              Text('Creator: $creatorName'), // Display creator's name
              Text(
                'Deadline: $formattedDeadline',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
