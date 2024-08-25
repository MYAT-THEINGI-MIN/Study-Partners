import 'package:flutter/material.dart';
import 'package:path/path.dart';

class PointSystemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Point System'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Leaderboard Point System',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _buildPointDescription(
              'Create Quiz',
              '+2 points for each quiz created.',
            ),
            _buildPointDescription(
              'Answer Quiz',
              '+[score] points for each quiz answered correctly. Points are awarded for the first attempt. You can answer multiple times but only the first correct attempt counts.',
            ),
            _buildPointDescription(
              'View Correct Answers',
              'No points awarded for viewing correct answers.',
            ),
            _buildPointDescription(
              'Create Plan',
              '+1 point per task added to a plan.',
            ),
            _buildPointDescription(
              'Complete Plan',
              '+2 points per task completed in the plan.',
            ),
            _buildPointDescription(
              'Delete Plan',
              '-1 point per task removed from a plan.',
            ),
            _buildPointDescription(
              'Add Note',
              '+1 point per note file created.',
            ),
            _buildPointDescription(
              'Delete Note',
              '-1 point per note file deleted.',
            ),
            _buildPointDescription(
              'Create Flashcard',
              '+1 point per flashcard created.',
            ),
            _buildPointDescription(
              'Delete Flashcard',
              '-1 point per flashcard deleted.',
            ),
            _buildPointDescription(
              'Study Timer',
              '+1 point per minute studied, starting from 15 minutes. Points are awarded for each minute after the first 15 minutes.The movement sensor contain on timer section so that if you move your device while studying, it will activate.',
            ),
            SizedBox(height: 20),
            Text(
              'Make sure to keep track of your activities to maximize your points!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointDescription(String action, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4,
        child: ListTile(
          title: Text(
            action,
          ),
          subtitle: Text(description),
        ),
      ),
    );
  }
}
