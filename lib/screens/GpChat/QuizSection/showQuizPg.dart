import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/screens/GpChat/QuizSection/createQuiz.dart';
import 'package:sp_test/screens/GpChat/QuizSection/quizTest.dart';

class ShowQuizPage extends StatelessWidget {
  final String groupId;

  ShowQuizPage({required this.groupId});

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
                  }))
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
                      subtitle: Text('Created by: $creatorName'),
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
