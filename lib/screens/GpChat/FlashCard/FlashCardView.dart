import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashCardView extends StatefulWidget {
  final String groupId;
  final String flashcardId;

  FlashCardView({required this.groupId, required this.flashcardId});

  @override
  _FlashCardViewState createState() => _FlashCardViewState();
}

class _FlashCardViewState extends State<FlashCardView> {
  late List<DocumentSnapshot> qaPairs;
  int currentIndex = -1;
  bool showBack = false;
  bool canDelete = false;

  @override
  void initState() {
    super.initState();
    checkUserPermission();
  }

  void checkUserPermission() async {
    // Get current user's UID
    String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid != null) {
      // Fetch the flashcard details
      DocumentSnapshot flashcardSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('Flashcards')
          .doc(widget.flashcardId)
          .get();

      // Get the creator UID from the flashcard data
      String creatorUid = flashcardSnapshot['creatorUid'];

      // Compare with current user's UID
      setState(() {
        canDelete = (currentUserUid == creatorUid);
      });
    }
  }

  void deleteFlashcard() async {
    // Delete the flashcard from Firestore
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('Flashcards')
        .doc(widget.flashcardId)
        .delete();

    // Navigate back or handle deletion completion
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcard Details'),
        actions: [
          if (canDelete)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Flashcard'),
                    content:
                        Text('Are you sure you want to delete this flashcard?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          deleteFlashcard();
                        },
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('Flashcards')
              .doc(widget.flashcardId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Flashcard not found');
            }

            var flashcard = snapshot.data!;
            String title = flashcard['title'];

            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('Flashcards')
                          .doc(widget.flashcardId)
                          .collection('QAPairs')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text('No question-answer pairs'));
                        }

                        qaPairs = snapshot.data!.docs;

                        if (currentIndex == -1) {
                          currentIndex = Random().nextInt(qaPairs.length);
                        }

                        return Center(
                          child: Container(
                            width: 300,
                            height: 300,
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  showBack
                                      ? ' ${qaPairs[currentIndex]['answer'] ?? 'N/A'}'
                                      : ' ${qaPairs[currentIndex]['question'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!showBack)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            showBack = true;
                                          });
                                        },
                                        child: Text('Show Answer'),
                                      ),
                                    if (showBack)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            showBack = false;
                                          });
                                        },
                                        child: Text('Show Question'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        int newIndex;
                        do {
                          newIndex = Random().nextInt(qaPairs.length);
                        } while (newIndex == currentIndex);

                        currentIndex = newIndex;
                        showBack = false;
                      });
                    },
                    child: Text('Next'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
