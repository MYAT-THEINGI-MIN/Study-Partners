import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sp_test/widgets/textfield.dart';

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
  List<String> _predefinedSubjects = [
    'Java',
    'Html',
    'CSS',
    'Flutter',
    'Art',
    'Japanese',
    'Korean',
    'Chinese',
    'English'
  ];

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
        'interests': newSubjects,
        'profileImageUrl': profileImageUrl,
      });
      Navigator.pop(context);
    } catch (e) {
      print('Failed to update profile: $e');
    }
  }

  void _showAddSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Subject'),
          content: TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              hintText: 'Enter subject',
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (_subjectController.text.isNotEmpty) {
                  setState(() {
                    _subjects.add(_subjectController.text.trim());
                    _predefinedSubjects.add(_subjectController.text.trim());
                  });
                  _subjectController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
              CustomTextField(
                controller: _usernameController,
                labelText: 'Username',
                showSuffixIcon: false,
                onSuffixIconPressed:
                    () {}, // Hide suffix icon for username field
              ),
              SizedBox(height: 8),
              CustomTextField(
                controller: _statusController,
                labelText: 'Status',
                showSuffixIcon: false,
                onSuffixIconPressed: () {}, // Hide suffix icon for status field
              ),
              SizedBox(height: 16),
              Text(
                'Studying Subjects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.deepPurple
                      : Colors.deepPurpleAccent,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                children: _subjects
                    .map(
                      (subject) => Container(
                        margin: EdgeInsets.only(right: 8, bottom: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.deepPurple[100]
                                  : Colors.deepPurpleAccent[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(subject.trim(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                    )),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                _removeSubject(_subjects.indexOf(subject));
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Subject',
                  border: OutlineInputBorder(),
                ),
                items: _predefinedSubjects.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: Theme.of(context).textTheme.bodySmall),
                  );
                }).toList()
                  ..add(
                    DropdownMenuItem<String>(
                      value: 'add_new',
                      child: Row(
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8.0),
                          Text('Add New Subject',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                onChanged: (String? newValue) {
                  if (newValue == 'add_new') {
                    _showAddSubjectDialog(context);
                  } else if (newValue != null &&
                      !_subjects.contains(newValue)) {
                    setState(() {
                      _subjects.add(newValue);
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
