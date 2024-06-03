import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/widgets/message.dart';

class Chatservice extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firebaseFirestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  Future<void> sendImageMessage(String receiverId, File file) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final firebaseStorageRef =
        FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    try {
      final uploadTask = firebaseStorageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      if (snapshot.state == TaskState.success) {
        final imageUrl = await snapshot.ref.getDownloadURL();

        print('Image uploaded successfully: $imageUrl');

        Message newMessage = Message(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: receiverId,
          message: '',
          imageUrl: imageUrl,
          timestamp: timestamp,
        );

        List<String> ids = [currentUserId, receiverId];
        ids.sort();
        String chatRoomId = ids.join("_");

        await _firebaseFirestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .add(newMessage.toMap());
      } else {
        print('Error uploading image: ${snapshot.state.toString()}');
        throw FirebaseException(
            plugin: 'firebase_storage', message: 'Upload failed');
      }
    } catch (error) {
      print('Error uploading image: $error');
      throw error;
    }
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firebaseFirestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
