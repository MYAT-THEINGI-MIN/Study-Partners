import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sp_test/screens/GpChat/EditGroup/addPartner.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _leaderNoteController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _privacy = 'Public';

  void _createGroup() async {
    String groupName = _groupNameController.text.trim();
    String subject = _subjectController.text.trim();
    String? profileUrl;

    if (groupName.isEmpty || subject.isEmpty || _privacy == null) {
      // Add validation or error handling if needed
      return;
    }

    try {
      // Get current user details
      User? user = _auth.currentUser;
      String adminId = user!.uid;
      String adminName = user.displayName ?? "Admin"; // Default to 'Admin'

      // Upload image file if selected
      if (_imageFile != null) {
        String imagePath =
            'group_profiles/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageReference =
            FirebaseStorage.instance.ref().child(imagePath);
        UploadTask uploadTask = storageReference.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        profileUrl = await snapshot.ref.getDownloadURL();
      }

      // Create a new group document
      DocumentReference groupRef = await _firestore.collection('groups').add({
        'groupName': groupName,
        'subject': subject,
        'StudyHardPoint': 100, // Initialize StudyHard points to 100
        'profileUrl': profileUrl ?? '',
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'members': [adminId],
        'leaderNote': _leaderNoteController.text.trim(), // Store leader note
        'privacy': _privacy, // Store privacy value
      });

      // Add the admin to the group members array
      await groupRef.update({
        'members': FieldValue.arrayUnion([adminId]),
      });

      // Ensure adminName is fetched and set correctly
      if (adminName == null) {
        // If displayName is null, fetch user info again (not expected to happen often)
        User? updatedUser = await _auth.currentUser;
        adminName = updatedUser!.displayName ?? "Admin";
      }

      // Create the LeaderBoard collection under the group document
      await groupRef.collection('LeaderBoard').doc(adminId).set({
        'name': adminName,
        'points': 0,
      });

      // Show snackbar and navigate back
      showTopSnackBar(context, 'Group created successfully');
      Navigator.pop(context);
    } catch (e) {
      // Handle errors
      print("Error creating group: $e");
      showTopSnackBar(context, 'Failed to create group: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _imageFile != null
                  ? CircleAvatar(
                      radius: 50.0,
                      backgroundImage: FileImage(_imageFile!),
                    )
                  : CircleAvatar(
                      radius: 50.0,
                      child: Icon(Icons.camera_alt),
                    ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple, // Deep purple shade 200
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple, // Deep purple shade 200
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _leaderNoteController,
              decoration: InputDecoration(
                labelText: 'Leader Note',
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple, // Deep purple shade 200
                ),
              ),
              maxLines: 3, // Adjust as needed
            ),
            SizedBox(height: 16.0),
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
                  _privacy = value;
                });
              },
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _createGroup,
              child: Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _subjectController.dispose();
    _leaderNoteController.dispose();
    super.dispose();
  }
}
