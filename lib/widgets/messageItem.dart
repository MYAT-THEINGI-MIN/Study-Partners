import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageItem extends StatelessWidget {
  final DocumentSnapshot document;
  final FirebaseAuth auth;
  final Function(DocumentReference) onDelete;

  MessageItem({
    required this.document,
    required this.auth,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isOwnMessage = data['senderId'] == auth.currentUser!.uid;

    return GestureDetector(
      onLongPress: isOwnMessage
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Message?'),
                  content:
                      Text('Are you sure you want to delete this message?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        onDelete(document.reference);
                        Navigator.of(context).pop();
                      },
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isOwnMessage ? Colors.blue : Colors.grey.shade300,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] !=
                  null) // Check if message contains an image
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    data['imageUrl'],
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              if (data['message'] != null &&
                  data['message'].isNotEmpty) // Check if message contains text
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    data['message'],
                    style: TextStyle(
                      color: isOwnMessage ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // Display send time for all messages
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  DateFormat('hh:mm a')
                      .format((data['timestamp'] as Timestamp).toDate()),
                  style: TextStyle(
                    color: isOwnMessage ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
