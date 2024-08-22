import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String? imageUrl;
  final bool isLink; // Add this field to track if the message contains a URL

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.imageUrl,
    required this.isLink, // Initialize this field in the constructor
  });

  // Convert Message to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'isLink': isLink, // Include this field in the map
    };
  }

  // Create a Message from a Map for Firestore
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      message: map['message'],
      timestamp: map['timestamp'],
      imageUrl: map['imageUrl'],
      isLink: map['isLink'] ?? false, // Handle default value
    );
  }
}
