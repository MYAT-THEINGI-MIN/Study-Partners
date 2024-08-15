import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _leaderNoteController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _privacy = 'Public';
  String? _subject;
  bool _showSuggestions = false;

  final List<String> _predefinedSubjects = [
    'Html',
    'Css',
    'Java',
    'Flutter',
    'AI',
    'Art',
    'Graphic Design',
    'UiUx',
    'English',
    'Japanese',
    'Korean',
    'Chinese',
  ];

  List<String> _filteredSubjects = [];

  @override
  void initState() {
    super.initState();
    _filteredSubjects = _predefinedSubjects;
    _subjectController.addListener(_filterSubjects);
  }

  void _filterSubjects() {
    setState(() {
      String input = _subjectController.text.toLowerCase();
      _filteredSubjects = _predefinedSubjects
          .where((subject) => subject.toLowerCase().contains(input))
          .toList();
      _showSuggestions = _subjectController.text.isNotEmpty;
    });
  }

  void _createGroup() async {
    String groupName = _groupNameController.text.trim();
    String subject = _subject?.trim() ?? '';
    String? profileUrl;

    if (groupName.isEmpty || subject.isEmpty || _privacy == null) {
      TopSnackBarWiidget(context, 'Please fill out all fields');
      return;
    }

    try {
      // Get current user details
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      String adminId = user.uid;
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(adminId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String adminName = userData?['username'] ?? 'Admin';

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
        'adminName': adminName,
        'timestamp': FieldValue.serverTimestamp(),
        'members': [adminId],
        'leaderNote': _leaderNoteController.text.trim(), // Store leader note
        'privacy': _privacy, // Store privacy value
        'joinRequests': [], // Initialize joinRequests as an empty array
      });

      // Add the admin to the group members array
      await groupRef.update({
        'members': FieldValue.arrayUnion([adminId]),
      });

      // Create the LeaderBoard collection under the group document
      await groupRef.collection('LeaderBoard').doc(adminId).set({
        'name': adminName,
        'id': adminId,
        'points': 0,
      });

      // Show snackbar and navigate back
      TopSnackBarWiidget(context, 'Group created successfully');

      Navigator.pop(context);
    } catch (e) {
      // Handle errors
      print("Error creating group: $e");
      TopSnackBarWiidget(context, 'Failed to create group: $e');
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
  void dispose() {
    _groupNameController.dispose();
    _leaderNoteController.dispose();
    _subjectController.dispose();
    super.dispose();
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
            TextField(
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
            // Show suggestions list only if _showSuggestions is true
            if (_showSuggestions)
              Container(
                height: 200.0,
                child: ListView(
                  children: _filteredSubjects.map((subject) {
                    return ListTile(
                      title: Text(subject),
                      onTap: () {
                        setState(() {
                          _subject = subject;
                          _subjectController.text = subject;
                          _showSuggestions = false;
                        });
                      },
                    );
                  }).toList(),
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
}
