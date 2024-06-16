import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sp_test/screens/GpChat/addPartner.dart';

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

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _groupSubjectController = TextEditingController();
    _profileUrl = widget.gpProfileUrl;
    fetchGroupDetails();
    fetchMemberCount();
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

  void _addPartner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPartnerPage(groupId: widget.groupId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Info'),
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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .collection('members')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(member['profileUrl'] ?? ''),
                          ),
                          title: Text(member['username']),
                          subtitle:
                              Text(member['status'] ?? 'last seen recently'),
                          trailing: Text(member['role'] ?? ''),
                        );
                      },
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
