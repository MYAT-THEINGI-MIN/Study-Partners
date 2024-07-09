import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/EditGroup/addPartner.dart'; // Make sure this import path is correct

class MemberList extends StatefulWidget {
  final String groupId;
  final bool isAdmin;

  MemberList({required this.groupId, required this.isAdmin});

  @override
  _MemberListState createState() => _MemberListState();
}

class _MemberListState extends State<MemberList> {
  List<Map<String, dynamic>> _members = [];
  int _memberCount = 0;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      final members = docSnapshot.data()?['members'] ?? [];

      final List<String> uids = List<String>.from(members);

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uids)
          .get();

      setState(() {
        _members = usersSnapshot.docs.map((doc) => doc.data()).toList();
        _memberCount = _members.length; // Update member count here
      });
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Removal'),
            content: Text('Are you sure you want to remove this member?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Remove'),
              ),
            ],
          );
        },
      );

      if (confirmed ?? false) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'members': FieldValue.arrayRemove([memberId]),
        });
        setState(() {
          _members.removeWhere((member) => member['uid'] == memberId);
          _memberCount = _members.length;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member removed successfully.')),
        );
      }
    } catch (e) {
      print('Error removing member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove member. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Member List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'MEMBERS ($_memberCount)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person_add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddPartnerPage(groupId: widget.groupId),
                      ),
                    ).then((_) {
                      // Refresh member count and list after adding a partner
                      fetchMembers();
                    });
                  },
                  color: Theme.of(context).primaryColor,
                  iconSize: 30,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        NetworkImage(member['profileImageUrl'] ?? ''),
                  ),
                  title: Text(member['username'] ?? ''),
                  subtitle: Text(member['subjects'] ?? ''),
                  trailing: widget.isAdmin
                      ? PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'remove') {
                              _removeMember(member['uid']);
                            }
                          },
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
