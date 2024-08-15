import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

void showTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50.0,
      left: MediaQuery.of(context).size.width * 0.1,
      right: MediaQuery.of(context).size.width * 0.1,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            message,
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  overlay?.insert(overlayEntry);
  Future.delayed(Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

class AddPartnerPage extends StatefulWidget {
  final String groupId;

  AddPartnerPage({required this.groupId});

  @override
  _AddPartnerPageState createState() => _AddPartnerPageState();
}

class _AddPartnerPageState extends State<AddPartnerPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  List<String> _existingMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingMembers();
  }

  Future<void> _loadExistingMembers() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    setState(() {
      _existingMembers = List<String>.from(groupDoc['members']);
    });
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final trimmedQuery = query.trim();
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: trimmedQuery)
          .where('username', isLessThanOrEqualTo: trimmedQuery + '\uf8ff')
          .get();

      setState(() {
        _searchResults = result.docs;
      });

      if (_searchResults.isEmpty) {
        showTopSnackBar(context, 'No users found');
      }
    } catch (e) {
      showTopSnackBar(context, 'Error searching users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addPartner(DocumentSnapshot user) async {
    if (_existingMembers.contains(user.id)) {
      showTopSnackBar(context, '${user['username']} is already in the group');
      return;
    }

    try {
      final userId = user.id;

      // Update the 'members' array in the 'groups' collection
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayUnion([userId])
      });

      // Add the user to the LeaderBoard collection under the group
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('LeaderBoard')
          .doc(userId)
          .set({
        'name': user['username'] ?? 'Unknown',
        'uid': userId,
        'points': 0,
      });

      setState(() {
        _existingMembers.add(userId);
      });

      showTopSnackBar(
          context, '${user['username']} has been added to the group');
    } catch (e) {
      showTopSnackBar(context, 'Error adding partner: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Partner'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search New Partner',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
          ),
          _isLoading
              ? CircularProgressIndicator()
              : Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isExistingMember =
                          _existingMembers.contains(user.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            user['profileImageUrl'] ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(user['username'] ?? 'Unknown'),
                        trailing: isExistingMember
                            ? Text('Already in group')
                            : IconButton(
                                icon: Icon(Icons.person_add),
                                onPressed: () => _addPartner(user),
                              ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
