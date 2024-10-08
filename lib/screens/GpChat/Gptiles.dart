import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/GpHomePg.dart';

class GroupTilesPage extends StatefulWidget {
  @override
  _GroupTilesPageState createState() => _GroupTilesPageState();
}

class _GroupTilesPageState extends State<GroupTilesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot> _groupStream;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    String currentUserId = _auth.currentUser!.uid;
    _groupStream = _firestore
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No groups found.'));
        }

        List<GroupTile> groupTiles = snapshot.data!.docs.map((doc) {
          return GroupTile(
            groupName: doc['groupName'],
            subject: doc['subject'],
            profileUrl: doc['profileUrl'] ?? '',
            groupId: doc.id,
          );
        }).toList();

        return ListView(
          children: groupTiles,
        );
      },
    );
  }
}

class GroupTile extends StatelessWidget {
  final String groupName;
  final String subject;
  final String profileUrl;
  final String groupId;

  GroupTile({
    required this.groupName,
    required this.subject,
    required this.profileUrl,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? bodyMedium = Theme.of(context).textTheme.bodyMedium;
    final TextStyle? bodySmall = Theme.of(context).textTheme.bodySmall;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
        child: profileUrl.isEmpty ? Icon(Icons.group) : null,
      ),
      title: Text(
        groupName,
        style: bodyMedium?.copyWith(
          color: bodyMedium.color, // Adjust color as per your theme
        ),
      ),
      subtitle: Text(
        subject,
        style: bodySmall?.copyWith(
          color: bodySmall.color, // Adjust color as per your theme
        ),
      ),
      onTap: () {
        // Navigate to Group Home Page with groupId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupHomePage(groupId: groupId),
          ),
        );
      },
    );
  }
}
