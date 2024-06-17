import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sp_test/screens/GpChat/addPartner.dart';

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
            color: Color.fromARGB(221, 210, 210, 210),
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

class EditGroupPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupSubject;
  final String gpProfileUrl;

  EditGroupPage({
    required this.groupId,
    required this.groupName,
    required this.groupSubject,
    required this.gpProfileUrl,
  });

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late TextEditingController _groupNameController;
  late TextEditingController _groupSubjectController;
  File? _imageFile;
  String? _profileUrl;
  bool _isSaving = false;
  int _memberCount = 0;
  String? _adminId;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _groupSubjectController = TextEditingController();
    _profileUrl = widget.gpProfileUrl;
    fetchGroupDetails();
    fetchMemberCount();
    fetchMembers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupSubjectController.dispose();
    super.dispose();
  }

  Future<void> fetchGroupDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        _groupNameController.text = data['groupName'] ?? widget.groupName;
        _groupSubjectController.text = data['subject'] ?? widget.groupSubject;
        _adminId = data['adminId'];
        checkIfAdmin();
        setState(() {
          _profileUrl = data['profileUrl'] ?? widget.gpProfileUrl;
        });
      }
    } catch (e) {
      print('Error fetching group details: $e');
    }
  }

  Future<void> fetchMemberCount() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .get();
      setState(() {
        _memberCount = querySnapshot.size;
      });
    } catch (e) {
      print('Error fetching member count: $e');
    }
  }

  Future<void> fetchMembers() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      final members = docSnapshot.data()?['members'] ?? [];

      final List<String> uids = members.cast<String>();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uids)
          .get();

      setState(() {
        _members = usersSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

  Future<void> checkIfAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _adminId == user.uid) {
        setState(() {
          _isAdmin = true;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        print('Image selected: ${_imageFile!.path}');
      }
    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageReference = FirebaseStorage.instance
          .ref()
          .child('group_images')
          .child('${widget.groupId}.jpg');
      final uploadTask = storageReference.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    String? imageUrl = _profileUrl;

    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    if (imageUrl != null) {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'groupName': _groupNameController.text,
          'subject': _groupSubjectController.text,
          'profileUrl': imageUrl,
        });
        Navigator.pop(context);
      } catch (e) {
        print('Error updating group: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update group. Please try again.'),
          ),
        );
      }
    } else {
      print('Failed to upload image');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image. Please try again.'),
        ),
      );
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _deleteGroup() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Group'),
          content: Text('Are you sure you want to delete this group?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .delete();
        Navigator.pop(context);
      } catch (e) {
        print('Error deleting group: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete group. Please try again.'),
          ),
        );
      }
    }
  }

  void _addPartner() async {
    // Navigate to AddPartnerPage and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPartnerPage(groupId: widget.groupId),
      ),
    );

    // Check if result is true (if a partner was successfully added)
    if (result == true) {
      // Fetch updated member list
      fetchMembers();
      // Show top snackbar confirmation
      showTopSnackBar(context, 'New partner added successfully.');
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
        // After removing from group, also update members list locally
        setState(() {
          _members.removeWhere((member) => member['uid'] == memberId);
        });
        // After removing from group, also update members list locally
        setState(() {
          _members.removeWhere((member) => member['uid'] == memberId);
        });

        showTopSnackBar(context, 'Member removed successfully.');
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
        title: Text('Group Info'),
        actions: _isAdmin
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _deleteGroup,
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : NetworkImage(_profileUrl ?? widget.gpProfileUrl)
                              as ImageProvider,
                      child:
                          _imageFile == null ? Icon(Icons.add_a_photo) : null,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _groupNameController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Edit Group Name',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _groupSubjectController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Edit Group Subject',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'MEMBERS ($_memberCount)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.person_add),
                        onPressed: _addPartner,
                        color: Theme.of(context).primaryColor,
                        iconSize: 30,
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
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
                      trailing: _isAdmin
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
                SizedBox(height: 70), // Space for the bottom button
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16.0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
