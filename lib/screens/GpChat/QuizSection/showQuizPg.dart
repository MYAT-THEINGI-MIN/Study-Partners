import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/QuizSection/createQuiz.dart';
import 'package:sp_test/screens/GpChat/QuizSection/quizTest.dart';

class ShowQuizPage extends StatelessWidget {
  final String groupId;

  ShowQuizPage({required this.groupId});

  void _showActionsSheet(
      BuildContext context, String quizId, String creatorUid) {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    if (creatorUid != currentUserUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not authorized to delete this quiz')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Quiz'),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  await _deleteQuiz(context, quizId, currentUserUid);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteQuiz(
      BuildContext context, String quizId, String userUid) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this quiz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        // Delete the quiz
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('Quiz')
            .doc(quizId)
            .delete();

        // Deduct points from the user's leaderboard entry
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('LeaderBoard')
            .doc(userUid)
            .update({
          'points': FieldValue.increment(-2), // Deduct 2 points
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Quiz deleted and points deducted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quizzes'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              child: const Text("Create New"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateQuizPage(groupId: groupId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('Quiz')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No quizzes available.'));
          }

          final quizzes = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index].data() as Map<String, dynamic>;
              final quizTitle = quiz['title'] ?? 'No Title';
              final creatorUid = quiz['creatorUid'] ?? 'Unknown';
              final creationDate =
                  (quiz['creationDate'] as Timestamp?)?.toDate() ??
                      DateTime.now();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(creatorUid)
                    .get(),
                builder: (context, userSnapshot) {
                  final creatorName =
                      userSnapshot.data?.get('username') ?? 'Unknown User';

                  return Card(
                    color: Colors.deepPurple.shade100,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(quizTitle),
                      subtitle: Text(
                        'Created by: $creatorName\nDate: ${creationDate.toLocal()}',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.more_vert),
                        onPressed: () {
                          _showActionsSheet(
                              context, quizzes[index].id, creatorUid);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizTestPage(
                              groupId: groupId,
                              quizId: quizzes[index].id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
