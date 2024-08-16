import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/widgets/FlashCardWidget.dart';
import 'package:sp_test/widgets/textfield.dart';

class EditFlashcardPage extends StatefulWidget {
  final String groupId;
  final String flashcardId;

  EditFlashcardPage({
    required this.groupId,
    required this.flashcardId,
  });

  @override
  _EditFlashcardPageState createState() => _EditFlashcardPageState();
}

class _EditFlashcardPageState extends State<EditFlashcardPage> {
  final _formKey = GlobalKey<FormState>();
  final _flashcards = <Map<String, dynamic>>[];
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool _showBack = false;
  int _editIndex = -1;
  String? _username;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchUsername();
    _loadFlashcardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsername() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _username = userDoc['username'];
    });
  }

  Future<void> _loadFlashcardData() async {
    DocumentSnapshot flashcardDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('Flashcards')
        .doc(widget.flashcardId)
        .get();

    if (flashcardDoc.exists) {
      setState(() {
        _titleController.text = flashcardDoc['title'];
      });

      QuerySnapshot qaPairsSnapshot =
          await flashcardDoc.reference.collection('QAPairs').get();
      setState(() {
        _flashcards.addAll(qaPairsSnapshot.docs.map((doc) => {
              'question': doc['question'],
              'answer': doc['answer'],
            }));
      });
    }
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
      _questionController.text = _flashcards[index]['question'];
      _answerController.text = _flashcards[index]['answer'];
      _editIndex = index;
      _showBack = false;
    });

    // Scroll to the editing card
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        index * 120.0, // Adjust the scroll offset based on card height
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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

    if (_formKey.currentState!.validate() && _flashcards.length >= 5) {
      String title = _titleController.text;
      String groupId = widget.groupId;
      String flashcardId = widget.flashcardId;

      // Update the flashcard document
      DocumentReference flashcardDoc = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('Flashcards')
          .doc(flashcardId);

      // Save title and updated QAPairs
      await flashcardDoc.update({
        'title': title,
      });

      // Delete existing QAPairs and add the updated ones
      final existingPairs = await flashcardDoc.collection('QAPairs').get();
      for (var doc in existingPairs.docs) {
        await doc.reference.delete();
      }

      for (var flashcard in _flashcards) {
        await flashcardDoc.collection('QAPairs').add({
          'question': flashcard['question'],
          'answer': flashcard['answer'],
        });
      }

      Navigator.pop(context);
    } else if (_flashcards.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least 5 question-answer pairs.'),
        ),
      );
    } else {
      print('Form is not valid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Flashcard'),
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
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  itemCount: _flashcards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _flashcards.length) {
                      return _buildNewCardInput();
                    } else {
                      return FlashcardWidget(
                        question: _flashcards[index]['question'],
                        answer: _flashcards[index]['answer'],
                        onEdit: () => _editFlashcard(index),
                        onDelete: () => _deleteFlashcard(index),
                        isHighlighted:
                            _editIndex == index, // Highlight the editing card
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
