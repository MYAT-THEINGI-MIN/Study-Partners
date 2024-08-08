import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

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
  String? _adminId;
  bool _isAdmin = false;
  String _privacy = 'Public';

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _groupSubjectController = TextEditingController();
    _profileUrl = widget.gpProfileUrl;
    fetchGroupDetails();
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
        _privacy = data['privacy'] ?? 'Public'; // Fetch and set privacy
        checkIfAdmin();
        setState(() {
          _profileUrl = data['profileUrl'] ?? widget.gpProfileUrl;
        });
      }
    } catch (e) {
      print('Error fetching group details: $e');
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
          'privacy': _privacy, // Update privacy field
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

  void _deleteGroup() async {
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
              onPressed: () async {
                Navigator.of(context).pop(true);
                try {
                  await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .delete();
                  TopSnackBarWiidget(context, 'Group deleted successfully');
                  Navigator.pop(context);
                } catch (e) {
                  print('Error deleting group: $e');
                  TopSnackBarWiidget(
                      context, 'Failed to delete group. Please try again.');
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Group'), // Update app bar title
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
                DropdownButtonFormField<String>(
                  value: _privacy,
                  decoration: InputDecoration(
                    labelText: 'Privacy',
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple, // Deep purple shade 200
                    ),
                  ),
                  items: ['Public', 'Private']
                      .map((privacy) => DropdownMenuItem<String>(
                            value: privacy,
                            child: Text(privacy),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _privacy = value ?? 'Public';
                    });
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
