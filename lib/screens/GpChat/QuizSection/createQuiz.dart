import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/widgets/textfield.dart';
import 'package:sp_test/widgets/topSnackBar.dart';
import 'package:uuid/uuid.dart';

class CreateQuizPage extends StatefulWidget {
  final String groupId;

  CreateQuizPage({required this.groupId});

  @override
  _CreateQuizPageState createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _quizTitleController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];

  @override
  void dispose() {
    _quizTitleController.dispose();
    _questions.forEach((question) {
      question['question'].dispose();
      question['answers'].forEach((controller) => controller.dispose());
    });
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': TextEditingController(),
        'answers': List.generate(4, (_) => TextEditingController()),
        'correctAnswerIndex': 0,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveQuiz() async {
    if (_quizTitleController.text.isEmpty || _questions.isEmpty) {
      TopSnackBarWiidget(context, 'Quiz title and questions are required.');
      return;
    }

    String quizId = Uuid().v4();
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    List<Map<String, dynamic>> questionsData = _questions.map((question) {
      return {
        'questionText': question['question'].text,
        'answers':
            question['answers'].map((controller) => controller.text).toList(),
        'correctAnswerIndex': question['correctAnswerIndex'],
      };
    }).toList();

    try {
      // Save the quiz to Firestore with the current date
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('Quiz')
          .doc(quizId)
          .set({
        'quizId': quizId,
        'title': _quizTitleController.text,
        'questions': questionsData,
        'marks': {}, // Initially, no marks stored
        'creatorUid': currentUserId, // Save the current user UID as creator
        'creationDate': FieldValue.serverTimestamp(), // Save the current date
      });

      // Update leaderboard points
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('LeaderBoard')
          .doc(currentUserId) // Assuming the document ID is the user UID
          .update({
        'points': FieldValue.increment(2), // Increment points by 2
      }).then((_) {
        TopSnackBarWiidget(
            context, 'Quiz created and points updated successfully!');
      }).catchError((e) {
        TopSnackBarWiidget(context, 'Failed to update leaderboard points.');
        print('Error updating points: $e');
      });
    } catch (e) {
      TopSnackBarWiidget(context, 'Failed to create quiz.');
      print('Error creating quiz: $e');
    }

    Navigator.pop(context);
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
        title: Text('Create Quiz'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _quizTitleController,
                  labelText: 'Quiz Title',
                  obscureText: false,
                  onSuffixIconPressed: () {},
                  showSuffixIcon: false, // Hide suffix icon for this field
                ),
                SizedBox(height: 16.0),
                ..._questions.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> question = entry.value;

                  return Card(
                    color: Colors.deepPurple[100], // Deep purple shade
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20), // Rounded corners
                    ),
                    margin: EdgeInsets.only(bottom: 16.0),
                    elevation: 4, // Add some shadow
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: question['question'],
                            labelText: 'Question ${index + 1}',
                            obscureText: false,
                            onSuffixIconPressed: () {},
                            showSuffixIcon:
                                false, // Hide suffix icon for this field
                          ),
                          SizedBox(height: 8.0),
                          ...question['answers']
                              .asMap()
                              .entries
                              .map((answerEntry) {
                            int answerIndex = answerEntry.key;
                            TextEditingController answerController =
                                answerEntry.value;

                            return RadioListTile<int>(
                              title: CustomTextField(
                                controller: answerController,
                                labelText: 'Answer ${answerIndex + 1}',
                                obscureText: false,
                                onSuffixIconPressed: () {},
                                showSuffixIcon:
                                    false, // Hide suffix icon for this field
                              ),
                              value: answerIndex,
                              groupValue: question['correctAnswerIndex'],
                              onChanged: (value) {
                                setState(() {
                                  question['correctAnswerIndex'] = value!;
                                });
                              },
                            );
                          }).toList(),
                          SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _removeQuestion(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _addQuestion,
                  child: Text('Add Question'),
                ),
                SizedBox(
                    height: 100), // To leave space for the button at the bottom
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveQuiz,
                child: Text('Save Quiz'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
