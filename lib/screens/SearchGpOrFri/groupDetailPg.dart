import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GroupDetailPage extends StatelessWidget {
  final Map<String, dynamic> groupDetails;

  GroupDetailPage({required this.groupDetails});

  void _requestToJoin(BuildContext context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.runTransaction((transaction) async {
          DocumentReference groupRef =
              _firestore.collection('groups').doc(groupDetails['groupId']);
          DocumentSnapshot snapshot = await transaction.get(groupRef);

          print('Group reference: ${groupRef.path}');
          print('Snapshot exists: ${snapshot.exists}');

          if (!snapshot.exists) {
            throw Exception("Group does not exist");
          }

          List<dynamic> joinRequests = snapshot['joinRequests'] ?? [];
          if (!joinRequests.contains(user.uid)) {
            joinRequests.add(user.uid);
            transaction.update(groupRef, {'joinRequests': joinRequests});
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request to join sent successfully')),
        );
      } catch (e) {
        print('Error requesting to join group: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  void _cancelRequest(BuildContext context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await _firestore.runTransaction((transaction) async {
          DocumentReference groupRef =
              _firestore.collection('groups').doc(groupDetails['groupId']);
          DocumentSnapshot snapshot = await transaction.get(groupRef);

          print('Group reference: ${groupRef.path}');
          print('Snapshot exists: ${snapshot.exists}');

          if (!snapshot.exists) {
            throw Exception("Group does not exist");
          }

          List<dynamic> joinRequests = snapshot['joinRequests'] ?? [];
          if (joinRequests.contains(user.uid)) {
            joinRequests.remove(user.uid);
            transaction.update(groupRef, {'joinRequests': joinRequests});
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request to join cancelled')),
        );
      } catch (e) {
        print('Error cancelling request to join group: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    bool isMember = user != null && groupDetails['members'].contains(user.uid);
    bool hasRequested =
        user != null && groupDetails['joinRequests']?.contains(user.uid) ??
            false;

    // Get screen width
    double screenWidth = MediaQuery.of(context).size.width;

    print('Group ID: ${groupDetails['groupId']}');
    print('Current User ID: ${user?.uid}');
    print('Group Details: $groupDetails');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: screenWidth,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(groupDetails['profileUrl'] ??
                        'https://via.placeholder.com/400x200'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Group Name: ${groupDetails['groupName']}',
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Active: ${groupDetails['lastActivityTimestamp'] != null ? DateFormat('yMMMd').add_jm().format(groupDetails['lastActivityTimestamp'].toDate()) : 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Subject: ${groupDetails['subject']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin Name: ${groupDetails['adminName']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Created At: ${DateFormat('yMMMd').format(groupDetails['timestamp'].toDate())}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Member Count: ${groupDetails['members'].length}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              Container(
                decoration: const BoxDecoration(color: Colors.deepPurple),
                height: 2,
              ),
              const SizedBox(height: 40),
              if (isMember)
                const Center(
                  child: Text(
                    'You are already in this group',
                    style: TextStyle(fontSize: 20, color: Colors.deepPurple),
                  ),
                )
              else if (hasRequested)
                Center(
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.red.shade400),
                    ),
                    onPressed: () => _cancelRequest(context),
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                )
              else
                Center(
                  child: ElevatedButton(
                    onPressed: () => _requestToJoin(context),
                    child: const Text('Request to Join'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
