import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/Service/attachmentHelper.dart';
import 'package:sp_test/widgets/textfield.dart';

class AddNewPlan extends StatefulWidget {
  final String groupId;

  AddNewPlan({required this.groupId});

  @override
  _AddNewPlanState createState() => _AddNewPlanState();
}

class _AddNewPlanState extends State<AddNewPlan> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _linkController = TextEditingController();
  DateTime? _selectedDeadline;

  final AttachmentHelper _attachmentHelper = AttachmentHelper();

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
      String groupId = widget.groupId; // Use the groupId passed to the widget
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch current user's username
      String? username;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          username = documentSnapshot['username'];
        }
      });

      // Upload creator's attachment to Firebase Storage and get the URL
      String? creatorAttachmentUrl;
      if (_attachmentHelper.creatorAttachment != null) {
        final ref = FirebaseStorage.instance.ref().child('attachments').child(
            DateTime.now().toString() +
                '_creator.' +
                _attachmentHelper.attachmentType!);
        await ref.putFile(_attachmentHelper.creatorAttachment!);
        creatorAttachmentUrl = await ref.getDownloadURL();
      } else if (_attachmentHelper.creatorAttachmentLink != null) {
        creatorAttachmentUrl = _attachmentHelper.creatorAttachmentLink;
      }

      // Add new plan document to Firestore
      DocumentReference planRef = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('plans')
          .add({
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'groupId': groupId,
        'uid': uid,
        'username': username, // Save username instead of uid
        'creatorAttachment': creatorAttachmentUrl,
        'attachmentType': _attachmentHelper.attachmentType,
      });

      // Create a 'completed' collection under the new plan document
      await planRef.collection('completed').doc(uid).set({
        'completedBy': uid,
        'completedAt': Timestamp.now(),
      });

      Navigator.pop(context);
    }
  }

  Widget _buildAttachmentPreview(BuildContext context) {
    if (_attachmentHelper.attachmentType != null) {
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
            if (_attachmentHelper.attachmentType == 'image' &&
                _attachmentHelper.creatorAttachment != null)
              Image.file(_attachmentHelper.creatorAttachment!, height: 100),
            if (_attachmentHelper.attachmentType == 'link' &&
                _attachmentHelper.creatorAttachmentLink != null)
              Expanded(
                child: Text(
                  'Link: ${_attachmentHelper.creatorAttachmentLink}',
                  style: TextStyle(color: Colors.deepPurple.shade300),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (_attachmentHelper.attachmentType != 'image' &&
                _attachmentHelper.creatorAttachment != null)
              Expanded(
                child: Text(
                  'File: ${_attachmentHelper.creatorAttachment!.path.split('/').last}',
                  style: TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.white),
              onPressed: () {
                setState(() {
                  _attachmentHelper.creatorAttachment = null;
                  _attachmentHelper.creatorAttachmentLink = null;
                  _attachmentHelper.attachmentType = null;
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attachment),
                      onPressed: () => _attachmentHelper.showAttachmentMenu(
                          context, setState, _linkController),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addNewPlan,
                        child: Text('Add Plan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
