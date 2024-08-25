import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CorrectAnswersPage extends StatelessWidget {
  final String quizId;
  final String groupId;

  CorrectAnswersPage({required this.quizId, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Correct Answers & User Marks'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('Quiz')
            .doc(quizId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No quiz data available.'));
          }

          final quizData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> questions = quizData['questions'] ?? [];
          final Map<String, dynamic> marks = quizData['marks'] ?? {};

          return ListView(
            children: [
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final questionData = entry.value as Map<String, dynamic>;
                final List<dynamic> answers = questionData['answers'] ?? [];
                final int correctAnswerIndex =
                    questionData['correctAnswerIndex'] ?? 0;

                return ListTile(
                  title: Text('Question ${index + 1}:'),
                  subtitle: Text(
                    'Correct Answer: ${answers.isNotEmpty ? answers[correctAnswerIndex] : 'N/A'}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              Divider(),
              ListTile(
                title: Text('Other Members Marks',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getUserDetails(marks.keys.toList()),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                    return Center(child: Text('No user data available.'));
                  }

                  final users = userSnapshot.data!;

                  return Column(
                    children: users.map((user) {
                      final userId = user['uid'];
                      final userMarks = marks[userId] ?? 0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['profileImageUrl'] != null &&
                                  user['profileImageUrl'].isNotEmpty
                              ? NetworkImage(user['profileImageUrl'])
                              : null,
                          child: user['profileImageUrl'] == null ||
                                  user['profileImageUrl'].isEmpty
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user['username'] ?? 'Unknown User'),
                        subtitle: Text('Marks: $userMarks'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getUserDetails(
      List<String> userIds) async {
    List<Map<String, dynamic>> users = [];

    for (String uid in userIds) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          users.add({
            'uid': uid,
            'username': userData['username'] ?? 'Unknown User',
            'profileImageUrl': userData['profileImageUrl'] ?? '',
          });
        }
      } catch (e) {
        print('Error fetching user data for UID $uid: $e');
      }
    }

    return users;
  }
}
