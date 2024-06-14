import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class GpChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> sendMessageToGroup(
      String groupId, String message, String senderId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'message': message,
        'senderId': senderId,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print("Error sending message: $e");
      throw e;
    }
  }

  Future<void> sendImageMessageToGroup(String groupId, File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef =
          _storage.ref().child('group_images').child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot storageSnapshot = await uploadTask;
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'imageUrl': downloadUrl,
        'senderId': 'admin', // Replace with actual sender id logic
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print("Error sending image message: $e");
      throw e;
    }
  }

  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    try {
      return _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print("Error retrieving messages: $e");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists) {
        final members = groupDoc.data()?['members'];
        if (members is List && members.isNotEmpty) {
          if (members.first is Map<String, dynamic>) {
            return List<Map<String, dynamic>>.from(members);
          } else if (members.first is String) {
            // Example: Convert comma-separated string to List<Map<String, dynamic>>
            List<Map<String, dynamic>> parsedMembers = [];
            members.forEach((memberString) {
              parsedMembers.add({
                'name': memberString
                    .toString(), // Adjust based on your actual member structure
                // Add other fields as needed
              });
            });
            return parsedMembers;
          } else {
            return [];
          }
        } else {
          return [];
        }
      } else {
        print('Group document does not exist');
        return [];
      }
    } catch (e) {
      print("Error retrieving group members: $e");
      throw e;
    }
  }
}
