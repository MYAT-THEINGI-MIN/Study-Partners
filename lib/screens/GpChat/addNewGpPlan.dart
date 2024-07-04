import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sp_test/widgets/textfield.dart';

class AddNewPlan extends StatefulWidget {
  @override
  _AddNewPlanState createState() => _AddNewPlanState();
}

class _AddNewPlanState extends State<AddNewPlan> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _linkController = TextEditingController();
  File? _creatorAttachment;
  String? _creatorAttachmentLink;
  String? _attachmentType;
  DateTime? _selectedDeadline;

  Future<void> _pickCreatorAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _creatorAttachment = File(pickedFile.path);
        _attachmentType = 'image';
      });
    }
  }

  Future<void> _pickCreatorFileAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc', 'mp4', 'avi'],
    );

    if (result != null) {
      setState(() {
        _creatorAttachment = File(result.files.single.path!);
        _attachmentType = result.files.single.extension;
      });
    }
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _addNewPlan() async {
    if (_formKey.currentState!.validate()) {
      String title = _titleController.text;
      String description = _descriptionController.text;
      DateTime deadline = _selectedDeadline!;
      String groupId = "YOUR_GROUP_ID"; // Replace with actual group ID
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Upload creator's attachment to Firebase Storage and get the URL
      String? creatorAttachmentUrl;
      if (_creatorAttachment != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('attachments')
            .child(DateTime.now().toString() + '_creator.' + _attachmentType!);
        await ref.putFile(_creatorAttachment!);
        creatorAttachmentUrl = await ref.getDownloadURL();
      } else if (_creatorAttachmentLink != null) {
        creatorAttachmentUrl = _creatorAttachmentLink;
        _attachmentType = 'link';
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('plans')
          .add({
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'groupId': groupId,
        'uid': uid,
        'completed': '',
        'creatorAttachment': creatorAttachmentUrl,
        'attachmentType': _attachmentType,
      });

      Navigator.pop(context);
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Image Attachment'),
              onTap: () {
                _pickCreatorAttachment();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('File Attachment'),
              onTap: () {
                _pickCreatorFileAttachment();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Link Attachment'),
              onTap: () {
                Navigator.pop(context);
                _showLinkAttachmentDialog();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLinkAttachmentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Link'),
          content: CustomTextField(
            controller: _linkController,
            labelText: 'Attachment Link',
            onSuffixIconPressed: () {},
            showSuffixIcon: false,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _creatorAttachmentLink = _linkController.text;
                  _attachmentType = 'link';
                });
                Navigator.of(context).pop();
              },
              child: Text('Add Link'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttachmentPreview(BuildContext context) {
    if (_attachmentType != null) {
      Color backgroundColor = Theme.of(context).brightness == Brightness.light
          ? Colors.deepPurple.shade100
          : Colors.grey.shade800;

      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(8.0),
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            if (_attachmentType == 'image' && _creatorAttachment != null)
              Image.file(_creatorAttachment!, height: 100),
            if (_attachmentType == 'link' && _creatorAttachmentLink != null)
              Expanded(
                child: Text(
                  'Link: $_creatorAttachmentLink',
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (_attachmentType != 'image' && _creatorAttachment != null)
              Expanded(
                child: Text(
                  'File: ${_creatorAttachment!.path.split('/').last}',
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.white),
              onPressed: () {
                setState(() {
                  _creatorAttachment = null;
                  _creatorAttachmentLink = null;
                  _attachmentType = null;
                });
              },
            ),
          ],
        ),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Plan'),
        actions: [
          IconButton(
            icon: Icon(Icons.attachment),
            onPressed: _showAttachmentMenu,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
                onSuffixIconPressed: () {},
                showSuffixIcon: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                onSuffixIconPressed: () {},
                showSuffixIcon: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              InkWell(
                onTap: () => _pickDeadline(context),
                child: IgnorePointer(
                  child: CustomTextField(
                    controller: _deadlineController,
                    labelText: 'Deadline',
                    onSuffixIconPressed: () {},
                    showSuffixIcon: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please pick a deadline';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              _buildAttachmentPreview(context),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addNewPlan,
                child: Text('Add Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
