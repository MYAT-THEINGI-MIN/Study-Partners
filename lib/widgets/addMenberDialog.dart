import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMemberDialog extends StatefulWidget {
  final String groupId;

  AddMemberDialog({required this.groupId});

  @override
  _AddMemberDialogState createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

  void _searchUsers(String query) async {
    if (query.isNotEmpty) {
      // Perform the query with case-insensitive search
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      print("Query Results: ${userSnapshot.docs}");

      setState(() {
        _searchResults = userSnapshot.docs;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _addMember(String userId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({
      'members': FieldValue.arrayUnion([userId])
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by username',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () => _searchUsers(_searchController.text),
              ),
            ),
            onChanged: (value) {
              // Perform search on every change if needed
              _searchUsers(value);
            },
          ),
          SizedBox(height: 16),
          Expanded(
            child: _searchResults.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot userDoc = _searchResults[index];
                      String username = userDoc['username'];
                      String userId = userDoc['uid'];

                      return ListTile(
                        title: Text(username),
                        onTap: () => _addMember(userId),
                      );
                    },
                  )
                : Center(child: Text('No users found')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
