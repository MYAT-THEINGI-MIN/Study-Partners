import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/SearchGpOrFri/groupDetailPg.dart';

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
  Map<String, dynamic>? _groupDetails;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        Map<String, dynamic> groupData =
            groupDoc.data() as Map<String, dynamic>;
        setState(() {
          _membersCount = (groupData['members'] ?? []).length;
          _groupDetails = groupData;
          // Ensure groupId is included in groupDetails
          _groupDetails!['groupId'] = widget.groupId;
        });
      }
    } catch (e) {
      print("Error fetching group details: $e");
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
        onTap: () {
          if (_groupDetails != null) {
            print('Group details being passed: $_groupDetails');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GroupDetailPage(groupDetails: _groupDetails!),
              ),
            );
          }
        },
      ),
    );
  }
}
