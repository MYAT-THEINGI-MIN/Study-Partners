import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  File? _imageFile; // Variable to store the selected image file
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  void _createGroup() async {
    String groupName = _groupNameController.text.trim();
    String subject = _subjectController.text.trim();
    String? profileUrl;

    if (groupName.isEmpty || subject.isEmpty) {
      // Add validation or error handling if needed
      return;
    }

    try {
      // Get current user details
      User? user = _auth.currentUser;
      String adminId = user!.uid;

      // Upload image file if selected
      if (_imageFile != null) {
        // Example path for image storage
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
        'profileUrl': profileUrl ?? '',
        'adminId': adminId,
        'timestamp': FieldValue.serverTimestamp(),
        'members': [adminId], // Include admin as the first member
      });

      // Add the admin to the group members array
      await groupRef.update({
        'members': FieldValue.arrayUnion([adminId]),
      });

      // Show snackbar and navigate back
      showTopSnackBar(context, 'Group created successfully');
      Navigator.pop(context); // Navigate back to previous screen
    } catch (e) {
      // Handle errors
      print("Error creating group: $e");
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
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: 'Subject'),
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
    super.dispose();
  }
}

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
