import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessageItem extends StatelessWidget {
  final DocumentSnapshot document;
  final FirebaseAuth auth;
  final void Function(DocumentReference) onDelete;

  MessageItem({
    required this.document,
    required this.auth,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    var alignment = (data['senderId'] == auth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    var messageTime = (data['timestamp'] as Timestamp).toDate();
    var formattedTime =
        "${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          onLongPress: () {
            if (data['senderId'] == auth.currentUser!.uid) {
              _showDeleteConfirmationDialog(context, document.reference);
            }
          },
          child: Column(
            crossAxisAlignment: (alignment == Alignment.centerRight)
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'],
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    SizedBox(height: 5),
                    Text(
                      formattedTime,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, DocumentReference messageRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                onDelete(messageRef);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
