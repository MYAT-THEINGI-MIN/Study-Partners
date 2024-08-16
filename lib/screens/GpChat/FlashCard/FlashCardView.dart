import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/FlashCard/editFlashCard.dart';

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
  bool canEditOrDelete = false;
  String? currentUserUid;
  String? adminId;

  @override
  void initState() {
    super.initState();
    checkUserPermission();
    fetchAdminId();
  }

  void checkUserPermission() async {
    currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid != null) {
      DocumentSnapshot flashcardSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('Flashcards')
          .doc(widget.flashcardId)
          .get();

      String creatorUid = flashcardSnapshot['creatorUid'];

      setState(() {
        canEditOrDelete = (currentUserUid == creatorUid);
      });
    }
  }

  void fetchAdminId() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    setState(() {
      adminId = groupSnapshot['adminId'];
    });
  }

  void updatePoints() async {
    if (currentUserUid != null) {
      DocumentReference leaderboardRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('LeaderBoard')
          .doc(currentUserUid);

      DocumentSnapshot leaderboardSnapshot = await leaderboardRef.get();

      if (leaderboardSnapshot.exists) {
        int currentPoints = leaderboardSnapshot['points'] ?? 0;

        await leaderboardRef.update({
          'points': currentPoints - 1,
        });
      }
    }
  }

  void deleteFlashcard() async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('Flashcards')
        .doc(widget.flashcardId)
        .delete();

    updatePoints();

    Navigator.pop(context);
  }

  void nextCard() {
    setState(() {
      // Get a new random index for the next card
      int newIndex;
      do {
        newIndex = Random().nextInt(qaPairs.length);
      } while (newIndex == currentIndex);

      currentIndex = newIndex;

      // Ensure the card flips back to front when navigating
      showBack = false;
    });
  }

  void showOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Flashcard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditFlashcardPage(
                        groupId: widget.groupId,
                        flashcardId: widget.flashcardId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Flashcard'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Flashcard'),
                      content: Text(
                          'Are you sure you want to delete this flashcard?'),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcard Details'),
        actions: [
          if (canEditOrDelete)
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: showOptions,
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

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              showBack = !showBack;
                            });
                          },
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 600),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              final flipAnimation =
                                  Tween(begin: pi, end: 0.0).animate(animation);
                              return AnimatedBuilder(
                                animation: flipAnimation,
                                builder: (context, child) {
                                  final angle = flipAnimation.value;
                                  final transform = Matrix4.rotationY(angle);
                                  return Transform(
                                    transform: transform,
                                    alignment: Alignment.center,
                                    child: child,
                                  );
                                },
                                child: child,
                              );
                            },
                            child: Container(
                              key: ValueKey(showBack),
                              width: 250, // Adjust the width for smaller card
                              height: 250, // Adjust the height for smaller card
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
                                        ? qaPairs[currentIndex]['answer'] ??
                                            'N/A'
                                        : qaPairs[currentIndex]['question'] ??
                                            'N/A',
                                    style: TextStyle(fontSize: 30),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: nextCard,
                        child: Text('Next'),
                      ),
                    ),
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
