import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/Service/RefreshIndicator.dart';
import 'package:sp_test/screens/GpChat/EditGroup/addPartner.dart';
import 'package:sp_test/widgets/topSnackBar.dart'; // Adjust import path as needed

class MemberList extends StatefulWidget {
  final String groupId;
  final bool isAdmin;

  MemberList({required this.groupId, required this.isAdmin});

  @override
  _MemberListState createState() => _MemberListState();
}

class _MemberListState extends State<MemberList> {
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _joinRequests = [];
  int _memberCount = 0;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    fetchMembersAndRequests();
  }

  Future<void> fetchMembersAndRequests() async {
    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (!groupDoc.exists) {
        print('Group document does not exist');
        return;
      }

      final members = groupDoc.data()?['members'] ?? [];
      final joinRequests = groupDoc.data()?['joinRequests'] ?? [];

      final memberUids = List<String>.from(members);
      final requestUids = List<String>.from(joinRequests);

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberUids)
          .get();

      List<QueryDocumentSnapshot> requestDocs = [];

      if (requestUids.isNotEmpty) {
        final requestsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: requestUids)
            .get();

        requestDocs = requestsSnapshot.docs;
      }

      setState(() {
        _members = usersSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _joinRequests = requestDocs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _memberCount = _members.length;
      });
    } catch (e) {
      print('Error fetching members or join requests: $e');
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

  Future<void> _handleJoinRequest(String userId, bool accept) async {
    try {
      if (accept) {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'members': FieldValue.arrayUnion([userId]),
          'joinRequests': FieldValue.arrayRemove([userId]),
        });

        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('LeaderBoard')
            .doc(userId)
            .set({
          'name': userSnapshot['username'],
          'points': 0,
        });

        TopSnackBarWiidget(context,
            'Request accepted. ${userSnapshot['username']} added to the group');
      } else {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'joinRequests': FieldValue.arrayRemove([userId]),
        });

        TopSnackBarWiidget(context, 'Request rejected');
      }

      fetchMembersAndRequests(); // Refresh member list and count
    } catch (e) {
      print('Error handling join request: $e');
      TopSnackBarWiidget(
          context, 'Failed to handle request. Please try again.');
    }
  }

  Future<void> _onRefresh() async {
    await fetchMembersAndRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Member List'),
      ),
      body: RefreshIndicatorWidget(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: Column(
          children: [
            if (_joinRequests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join Requests',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _joinRequests.length,
                      itemBuilder: (context, index) {
                        final request = _joinRequests[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(request['profileImageUrl'] ?? ''),
                          ),
                          title: Text(request['username'] ?? ''),
                          subtitle: Text(request['subjects'] ?? ''),
                          trailing: widget.isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.check),
                                      onPressed: () {
                                        _handleJoinRequest(
                                            request['uid'], true);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () {
                                        _handleJoinRequest(
                                            request['uid'], false);
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
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
                        fetchMembersAndRequests(); // Refresh member list after adding a partner
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
                                TopSnackBarWiidget(context, 'Removed');
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
      ),
    );
  }
}
