import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveGroupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> leaveGroup(String groupId) async {
    final String currentUserId = _auth.currentUser!.uid;

    try {
      // Remove the current user from the group members list
      await _firestore.collection('group_chat_rooms').doc(groupId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });

      // Optionally, delete the messages of the user from the group
      // This is commented out as per your requirement
      // await _firestore
      //     .collection('group_chat_rooms')
      //     .doc(groupId)
      //     .collection('messages')
      //     .where('senderId', isEqualTo: currentUserId)
      //     .get()
      //     .then((snapshot) {
      //   for (DocumentSnapshot ds in snapshot.docs) {
      //     ds.reference.delete();
      //   }
      // });
    } catch (e) {
      print('Error leaving group: $e');
      throw e;
    }
  }
}
