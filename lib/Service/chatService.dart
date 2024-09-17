import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/Service/GpLinkClass.dart';
import 'package:sp_test/widgets/message.dart';
import 'package:url_launcher/url_launcher.dart'; // Add dependency for URL detection

class Chatservice extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Function to extract URLs from a message
  List<String> _extractUrls(String message) {
    final RegExp urlExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
      multiLine: false,
    );
    return urlExp.allMatches(message).map((match) => match.group(0)!).toList();
  }

  // Function to extract domain from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return '';
    }
  }

  // Function to save link recommendation to Firestore
  Future<void> _saveLinkRecommendation(String domain) async {
    final linkRef =
        _firebaseFirestore.collection('LinksRecommendation').doc(domain);
    await linkRef.set({
      'domain': domain,
      'count': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Function to send a message in a peer-to-peer chat
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    // Detect URLs and extract domains
    final urls = _extractUrls(message);
    final domains = urls.map(_extractDomain).toSet(); // Remove duplicates

    // Save link recommendations
    for (String domain in domains) {
      if (domain.isNotEmpty) {
        await _saveLinkRecommendation(domain);
      }
    }

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isLink: urls.isNotEmpty, // Indicate if the message contains any URL
    );

    // Ensure a unique chat room ID based on user IDs
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // Add the chat room document with userIds field
    await _firebaseFirestore.collection('chat_rooms').doc(chatRoomId).set({
      'userIds': ids, // Store the list of user IDs in the chat room document
    });
    await _firebaseFirestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Function to send an image message in a peer-to-peer chat
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
          isLink: false, // Image messages do not have URLs
        );

        // Ensure a unique chat room ID based on user IDs
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

  // Function to get messages in a peer-to-peer chat
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

  //////////// Group Chat Methods//////////////////////

  // Function to send a message in a group chat
  Future<void> sendGroupMessage(String groupId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    // Check if message contains any URL
    final List<String> urls = _extractUrls(message);

    // Create a message object
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: groupId,
      message: message,
      timestamp: timestamp,
      isLink: urls.isNotEmpty, // Indicate if the message contains any URL
    );

    // Save message to Firestore
    await _firebaseFirestore
        .collection('group_chat_rooms')
        .doc(groupId)
        .collection('messages')
        .add(newMessage.toMap());

    // If URLs are found, save them to the 'grouplinks' collection
    if (urls.isNotEmpty) {
      await _saveLinksForGroup(groupId, urls);
    }
  }

// Function to save URLs to the 'grouplinks' collection
  Future<void> _saveLinksForGroup(String groupId, List<String> urls) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    for (String url in urls) {
      GroupLink newLink = GroupLink(
        groupId: groupId,
        link: url,
        addedBy: currentUserId,
        timestamp: timestamp,
      );

      await _firebaseFirestore
          .collection('groups')
          .doc(groupId)
          .collection('grouplinks')
          .add(newLink.toMap());
    }
  }

  // Function to send an image message in a group chat
  Future<void> sendGroupImageMessage(String groupId, File file) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('group_images')
        .child("$fileName.jpg");

    try {
      final uploadTask = firebaseStorageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      if (snapshot.state == TaskState.success) {
        final imageUrl = await snapshot.ref.getDownloadURL();

        print('Group image uploaded successfully: $imageUrl');

        Message newMessage = Message(
          senderId: currentUserId,
          senderEmail: currentUserEmail,
          receiverId: groupId,
          message: '',
          imageUrl: imageUrl,
          timestamp: timestamp,
          isLink: false, // Image messages do not have URLs
        );

        await _firebaseFirestore
            .collection('group_chat_rooms')
            .doc(groupId)
            .collection('messages')
            .add(newMessage.toMap());
      } else {
        print('Error uploading group image: ${snapshot.state.toString()}');
        throw FirebaseException(
            plugin: 'firebase_storage', message: 'Upload failed');
      }
    } catch (error) {
      print('Error uploading group image: $error');
      throw error;
    }
  }

  // Function to get messages in a group chat
  Stream<QuerySnapshot> getMessagesForGroup(String groupId) {
    return _firebaseFirestore
        .collection('group_chat_rooms')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
