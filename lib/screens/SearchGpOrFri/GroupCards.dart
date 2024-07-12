import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupCard extends StatefulWidget {
  final String profileUrl;
  final String groupName;
  final String subject;
  final String groupId;

  GroupCard({
    required this.profileUrl,
    required this.groupName,
    required this.subject,
    required this.groupId,
  });

  @override
  _GroupCardState createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  int _membersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMembersCount();
  }

  Future<void> _fetchMembersCount() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        List<dynamic> members = groupDoc['members'] ?? [];
        setState(() {
          _membersCount = members.length;
        });
      }
    } catch (e) {
      print("Error fetching members count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(widget.profileUrl.isNotEmpty
              ? widget.profileUrl
              : 'https://via.placeholder.com/150'),
        ),
        title: Text(widget.groupName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${widget.subject}'),
            Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 4),
                Text('$_membersCount members'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
