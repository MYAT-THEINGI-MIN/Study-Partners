import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/widgets/FlashCardWidget.dart';
import 'package:sp_test/widgets/textfield.dart';

class CreateFlashcardPage extends StatefulWidget {
  final String groupId;

  CreateFlashcardPage({required this.groupId});

  @override
  _CreateFlashcardPageState createState() => _CreateFlashcardPageState();
}

class _CreateFlashcardPageState extends State<CreateFlashcardPage> {
  final _formKey = GlobalKey<FormState>();
  final _flashcards = <Map<String, String>>[];
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool _showBack = false;
  int _editIndex = -1;
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _username = userDoc['username'];
    });
  }

  void _addFlashcard() {
    setState(() {
      if (_editIndex >= 0) {
        _flashcards[_editIndex] = {
          'question': _questionController.text,
          'answer': _answerController.text,
        };
        _editIndex = -1;
      } else {
        _flashcards.add({
          'question': _questionController.text,
          'answer': _answerController.text,
        });
      }
      _questionController.clear();
      _answerController.clear();
      _showBack = false;
    });
  }

  void _editFlashcard(int index) {
    setState(() {
      _questionController.text = _flashcards[index]['question']!;
      _answerController.text = _flashcards[index]['answer']!;
      _editIndex = index;
      _showBack = false;
    });
  }

  void _deleteFlashcard(int index) {
    setState(() {
      _flashcards.removeAt(index);
    });
  }

  Future<void> _saveFlashcards() async {
    if (_username == null) {
      print('Username not fetched yet');
      return;
    }

    // Add any remaining flashcard in the input fields before saving
    if (_questionController.text.isNotEmpty ||
        _answerController.text.isNotEmpty) {
      _addFlashcard();
    }

    if (_formKey.currentState!.validate() && _flashcards.isNotEmpty) {
      String title = _titleController.text;
      String groupId = widget.groupId;
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DateTime now = DateTime.now();

      // Create the flashcard document
      DocumentReference flashcardDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('Flashcards')
          .add({
        'title': title,
        'creatorUid': uid,
        'creatorUsername': _username,
        'createdDate': now,
      });

      // Add each question-answer pair as a separate document in a sub-collection
      for (var flashcard in _flashcards) {
        await flashcardDoc.collection('QAPairs').add({
          'question': flashcard['question'],
          'answer': flashcard['answer'],
        });
      }

      Navigator.pop(context);
    } else {
      print('Form is not valid or flashcards list is empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Flashcard'),
        actions: [
          ElevatedButton(
            onPressed: _saveFlashcards,
            child: Text('Save'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Flashcard Title',
                onSuffixIconPressed: () {},
                showSuffixIcon: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _flashcards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _flashcards.length) {
                      return _buildNewCardInput();
                    } else {
                      return FlashcardWidget(
                        question: _flashcards[index]['question']!,
                        answer: _flashcards[index]['answer']!,
                        onEdit: () => _editFlashcard(index),
                        onDelete: () => _deleteFlashcard(index),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewCardInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _showBack
                  ? CustomTextField(
                      controller: _answerController,
                      labelText: 'Answer / Definition',
                      onSuffixIconPressed: () {},
                      showSuffixIcon: false,
                    )
                  : CustomTextField(
                      controller: _questionController,
                      labelText: 'Question / Term',
                      onSuffixIconPressed: () {},
                      showSuffixIcon: false,
                    ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showBack = !_showBack;
                });
              },
              child: Text(_showBack ? 'Show Front' : 'Show Back'),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: Icon(Icons.add, size: 20, color: Colors.white),
                      onPressed: _addFlashcard,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
