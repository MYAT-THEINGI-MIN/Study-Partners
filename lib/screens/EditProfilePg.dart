import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePg extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePg({required this.userData});

  @override
  _EditProfilePgState createState() => _EditProfilePgState();
}

class _EditProfilePgState extends State<EditProfilePg> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  File? _profileImage;

  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.userData['username'] ?? '';
    _statusController.text = widget.userData['status'] ?? '';
    String subjects = widget.userData['subjects'] ?? '';
    if (subjects.isNotEmpty) {
      _subjects = subjects.split(',');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _statusController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = FirebaseAuth.instance.currentUser!.uid;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$fileName.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    }
  }

  void _addSubject(String subject) {
    setState(() {
      _subjects.add(subject);
      _subjectController.clear();
    });
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
    });
  }

  Future<void> _updateProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    try {
      String? profileImageUrl = widget.userData['profileImageUrl'];
      if (_profileImage != null) {
        profileImageUrl = await _uploadImage(_profileImage!);
      }

      String newSubjects = _subjects.join(', ');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'username': _usernameController.text,
        'status': _statusController.text,
        'subjects': newSubjects,
        'profileImageUrl': profileImageUrl,
      });
      Navigator.pop(context);
    } catch (e) {
      print('Failed to update profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : NetworkImage(widget.userData['profileImageUrl'] ??
                          'https://example.com/default.jpg') as ImageProvider,
                  child: Icon(Icons.camera_alt,
                      size: 50, color: Colors.white.withOpacity(0.7)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _statusController,
                decoration: InputDecoration(labelText: 'Status'),
              ),
              SizedBox(height: 16),
              Text('Studying Subjects', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Wrap(
                children: _subjects
                    .map((subject) => Container(
                          margin: EdgeInsets.only(right: 8, bottom: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(subject),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  _removeSubject(_subjects.indexOf(subject));
                                },
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(labelText: 'Add Subject'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {
                      String subject = _subjectController.text.trim();
                      if (subject.isNotEmpty) {
                        _addSubject(subject);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
