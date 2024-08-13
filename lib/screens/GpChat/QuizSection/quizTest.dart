import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuizTestPage extends StatefulWidget {
  final String groupId;
  final String quizId;

  QuizTestPage({required this.groupId, required this.quizId});

  @override
  _QuizTestPageState createState() => _QuizTestPageState();
}

class _QuizTestPageState extends State<QuizTestPage> {
  late Future<DocumentSnapshot> _quizData;
  final Map<int, int?> _userAnswers = {}; // Store answers for each question

  @override
  void initState() {
    super.initState();
    _quizData = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('Quiz')
        .doc(widget.quizId)
        .get();
  }

  Future<void> _submitAnswers() async {
    try {
      // Calculate marks
      final quizSnapshot = await _quizData;
      final quizData = quizSnapshot.data() as Map<String, dynamic>;
      final questions = quizData['questions'] as List<dynamic>;

      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i] as Map<String, dynamic>;
        final correctAnswerIndex = question['correctAnswerIndex'] as int;

        if (_userAnswers[i] == correctAnswerIndex) {
          score++;
        }
      }

      // Get user ID from authentication
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        // Handle case where user is not logged in
        throw Exception('User not logged in');
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('Quiz')
          .doc(widget.quizId)
          .update({
        'marks.$userId': score,
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Quiz Submitted'),
          content:
              Text('Your answers have been submitted. Your score is $score.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to the previous screen
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error submitting answers: $e');
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred while submitting your answers.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Test'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _quizData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Quiz not found.'));
          }

          final quiz = snapshot.data!.data() as Map<String, dynamic>;
          final questions = quiz['questions'] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index] as Map<String, dynamic>;
                      final questionText =
                          question['questionText'] ?? 'No question';
                      final answers = question['answers'] as List<dynamic>;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${index + 1}: $questionText',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              ...answers
                                  .asMap()
                                  .entries
                                  .where((entry) =>
                                      entry.value != null &&
                                      entry.value.isNotEmpty)
                                  .map((entry) {
                                final answerIndex = entry.key;
                                final answer = entry.value as String;

                                return RadioListTile<int>(
                                  title: Text(answer),
                                  value: answerIndex,
                                  groupValue: _userAnswers[index] ?? -1,
                                  onChanged: (value) {
                                    setState(() {
                                      _userAnswers[index] = value;
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _submitAnswers,
                    child: Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          Size(double.infinity, 50), // Make button full width
                      padding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
