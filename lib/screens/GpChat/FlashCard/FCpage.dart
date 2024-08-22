import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';
import 'package:sp_test/screens/GpChat/FlashCard/FlashCardView.dart';
import 'package:sp_test/screens/GpChat/FlashCard/createFC.dart';

class FlashcardsPage extends StatelessWidget {
  final String groupId;

  FlashcardsPage({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateFlashcardPage(groupId: groupId),
                ),
              );
            },
            child: Text('Create New'),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('Flashcards')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No flashcards available'));
          }

          List<DocumentSnapshot> flashcards = snapshot.data!.docs;

          return ListView.builder(
            itemCount: flashcards.length,
            itemBuilder: (context, index) {
              var flashcard = flashcards[index];
              String title = flashcard['title'];
              String creatorUsername =
                  flashcard['creatorUsername'] ?? 'Unknown';
              DateTime createdDate =
                  (flashcard['createdDate'] as Timestamp).toDate();
              String formattedDate = DateFormat.yMMMd().format(createdDate);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlashCardView(
                        groupId: groupId,
                        flashcardId: flashcard
                            .id, // Pass the flashcard id to FlashCardView
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.0),
                        Text('Created by: $creatorUsername'),
                        SizedBox(height: 4.0),
                        Text('Created At: $formattedDate'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
