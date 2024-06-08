import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MessageItem extends StatelessWidget {
  final DocumentSnapshot document;
  final FirebaseAuth auth;
  final String? userProfilePicUrl;
  final String? receiverProfilePicUrl;
  final Function(DocumentReference) onDelete;

  MessageItem({
    required this.document,
    required this.auth,
    this.userProfilePicUrl,
    this.receiverProfilePicUrl,
    required this.onDelete,
  });

  void showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _saveImage(BuildContext context, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = path.join(directory.path, path.basename(imageUrl));
        final imageFile = File(filePath);
        await imageFile.writeAsBytes(response.bodyBytes);
        print("Image saved to $filePath");

        showTopSnackBar(context, 'Saved Image');
      } else {
        print("Failed to download image.");
      }
    } catch (e) {
      print("Error saving image: $e");
    }
  }

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
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        data['imageUrl'],
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon: Icon(Icons.save_alt, color: Colors.white),
                        onPressed: () => _saveImage(context, data['imageUrl']),
                      ),
                    ),
                  ],
                ),
              if (data['message'] != null &&
                  data['message'].isNotEmpty) // Check if message contains text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
