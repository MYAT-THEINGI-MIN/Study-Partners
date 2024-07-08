import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/Service/attachmentHelper.dart';
import 'package:sp_test/widgets/textfield.dart';

class PlanDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final DateTime deadline;
  final String planId;
  final String groupId;

  PlanDetailPage({
    required this.title,
    required this.description,
    required this.deadline,
    required this.planId,
    required this.groupId,
  });

  @override
  _PlanDetailPageState createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  final AttachmentHelper _attachmentHelper = AttachmentHelper();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _comment = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitted = false;

  Future<void> _submitWork() async {
    if (_attachmentHelper.attachmentType == null ||
        (_attachmentHelper.attachmentType == 'image' &&
            _attachmentHelper.creatorAttachment == null) ||
        (_attachmentHelper.attachmentType == 'file' &&
            _attachmentHelper.creatorAttachment == null) ||
        (_attachmentHelper.attachmentType == 'link' &&
            _attachmentHelper.creatorAttachmentLink == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please attach a file or link before submitting')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      // Handle user not being logged in
      return;
    }
    String uid = user.uid;

    String? fileUrl;
    if (_attachmentHelper.attachmentType == 'image' ||
        _attachmentHelper.attachmentType == 'file') {
      // Upload file to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child(
          'groups/${widget.groupId}/plans/${widget.planId}/completed/$uid/${_attachmentHelper.creatorAttachment!.path.split('/').last}');
      UploadTask uploadTask =
          storageRef.putFile(_attachmentHelper.creatorAttachment!);
      TaskSnapshot taskSnapshot = await uploadTask;
      fileUrl = await taskSnapshot.ref.getDownloadURL();
    }

    String? link;
    if (_attachmentHelper.attachmentType == 'link') {
      link = _attachmentHelper.creatorAttachmentLink;
    }

    // Store the data in Firestore
    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('plans')
        .doc(widget.planId)
        .collection('completed')
        .doc(uid)
        .set({
      'uid': uid,
      'comment': _comment.text,
      'fileUrl': fileUrl,
      'link': link,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the state to show submission message and delete button
    setState(() {
      _isSubmitted = true;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Work submitted successfully')),
    );
  }

  Future<void> _deleteWork() async {
    User? user = _auth.currentUser;
    if (user == null) {
      // Handle user not being logged in
      return;
    }
    String uid = user.uid;

    // Delete the submitted work from Firestore
    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('plans')
        .doc(widget.planId)
        .collection('completed')
        .doc(uid)
        .delete();

    // Update the state to revert the UI back to the initial state
    setState(() {
      _isSubmitted = false;
      _attachmentHelper.creatorAttachment = null;
      _attachmentHelper.creatorAttachmentLink = null;
      _attachmentHelper.attachmentType = null;
      _comment.clear();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Work deleted successfully')),
    );
  }

  Widget _buildAttachmentPreview() {
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
    return Container(); // Return empty container if no attachment set
  }

  @override
  Widget build(BuildContext context) {
    // Format the deadline date
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    final String formattedDeadline = formatter.format(widget.deadline);

    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Detail'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: SizedBox(
              width: 400, // Fixed width for the card
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      SizedBox(height: 10),
                      Text(widget.description),
                      SizedBox(height: 10),
                      Text(
                        'Deadline: $formattedDeadline',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      SizedBox(height: 20),
                      if (!_isSubmitted) ...[
                        _buildAttachmentPreview(),
                        SizedBox(height: 20),
                        CustomTextField(
                          controller: _comment,
                          labelText: 'Comment',
                          onSuffixIconPressed: () {},
                          showSuffixIcon: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Comment cannot be empty';
                            }
                            return null;
                          },
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.attachment),
                              onPressed: () =>
                                  _attachmentHelper.showAttachmentMenu(
                                context,
                                setState,
                                _linkController,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitWork,
                                child: Text('Submit Your Work'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'You have done this work',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _deleteWork,
                          child: Text('Delete Work'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _comment.dispose();
    super.dispose();
  }
}
