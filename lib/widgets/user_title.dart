import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/Service/chatService.dart';
import 'package:sp_test/screens/chatRoom.dart';

class UserTile extends StatelessWidget {
  final DocumentSnapshot userDoc;
  final String currentUserId;
  final Chatservice chatService;
  final Function(String) onDelete;

  UserTile({
    required this.userDoc,
    required this.currentUserId,
    required this.chatService,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = userDoc.data()! as Map<String, dynamic>;
    String username = data['username'] ?? 'No Username';
    String uid = data['uid'] ?? '';
    String? profileUrl = data['profileImageUrl'];
    String status = data['status'] ?? 'No Status';

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getMessages(currentUserId, uid),
      builder: (context, messageSnapshot) {
        if (messageSnapshot.hasError) {
          return Text("Error loading messages");
        }

        if (messageSnapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading messages...");
        }

        List<DocumentSnapshot> messages = messageSnapshot.data!.docs;
        String recentMessage = messages.isNotEmpty
            ? (messages.last.data()! as Map<String, dynamic>)['message'] ?? ''
            : '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                ? NetworkImage(profileUrl)
                : AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          title: Text(username),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(recentMessage),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoom(
                  receiverUserName: username,
                  receiverUserId: uid,
                ),
              ),
            );
          },
          onLongPress: () => onDelete(uid),
        );
      },
    );
  }
}
