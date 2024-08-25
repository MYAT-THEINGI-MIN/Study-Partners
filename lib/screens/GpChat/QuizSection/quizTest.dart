import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'correctAnsPg.dart'; // Adjust this import based on your file structure

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
  int? _previousScore;
  bool _quizCompleted = false; // Track if the quiz was completed

  @override
  void initState() {
    super.initState();
    _quizData = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('Quiz')
        .doc(widget.quizId)
        .get();

    _checkPreviousScore();
  }

  Future<void> _checkPreviousScore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final quizSnapshot = await _quizData;
    final quizData = quizSnapshot.data() as Map<String, dynamic>;
    final marks = quizData['marks'] as Map<String, dynamic>;

    if (marks.containsKey(userId)) {
      setState(() {
        _previousScore = marks[userId] as int?;
        _quizCompleted =
            true; // Mark quiz as completed if there's a previous score
      });
    }
  }

  Future<void> _submitAnswers() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('User not logged in'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_previousScore != null) {
      final quizSnapshot = await _quizData;
      final quizData = quizSnapshot.data() as Map<String, dynamic>;
      final questions = quizData['questions'] as List<dynamic>;

      int currentScore = 0;
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i] as Map<String, dynamic>;
        final correctAnswerIndex = question['correctAnswerIndex'] as int;

        if (_userAnswers[i] == correctAnswerIndex) {
          currentScore++;
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Quiz Already Taken'),
          content: Text(
            'You have already taken this quiz. Your previous score is $_previousScore.\n'
            'Your current score is $currentScore. The previous score is retained.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to the previous screen
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
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

      final batch = FirebaseFirestore.instance.batch();
      final quizRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('Quiz')
          .doc(widget.quizId);
      final leaderboardRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('LeaderBoard')
          .doc(userId);

      batch.update(quizRef, {
        'marks.$userId': score,
      });

      batch.update(leaderboardRef, {
        'points': FieldValue.increment(score),
      });

      await batch.commit();

      setState(() {
        _quizCompleted = true; // Mark quiz as completed
      });

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
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error submitting answers: $e');
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
    // Update the group's last activity timestamp
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupRef.update({
      'lastActivityTimestamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Test'),
        actions: [
          if (_previousScore != null)
            IconButton(
              icon: Icon(Icons.visibility),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CorrectAnswersPage(
                      groupId: widget.groupId,
                      quizId: widget.quizId,
                    ),
                  ),
                );
              },
            ),
        ],
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

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount:
                      questions.length + 1, // Add one for the "Complete" button
                  itemBuilder: (context, index) {
                    if (index < questions.length) {
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
                    } else {
                      // This is the last item, which is the "Complete" button
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: _submitAnswers,
                          child: Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            padding: EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
