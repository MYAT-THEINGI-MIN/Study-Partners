import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/widgets/textfield.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

class AddNewFolderNotePage extends StatefulWidget {
  final String groupId;

  AddNewFolderNotePage({required this.groupId});

  @override
  _AddNewFolderNotePageState createState() => _AddNewFolderNotePageState();
}

class _AddNewFolderNotePageState extends State<AddNewFolderNotePage> {
  final TextEditingController _titleController = TextEditingController();
  List<PlatformFile>? _files;
  bool isUploading = false;

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx'],
    );

    if (result != null) {
      setState(() {
        _files = result.files;
      });
    }
  }

  Future<void> _uploadNote() async {
    if (_titleController.text.isEmpty || _files == null || _files!.isEmpty) {
      TopSnackBarWiidget(context, 'Title and files are required!');
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      List<String> fileUrls = await _uploadFiles();

      // Add the note to Firestore
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('notes')
          .add({
        'title': _titleController.text,
        'files': fileUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': uid,
      });

      // Update the points for the current user
      await _updateUserPoints(uid);

      setState(() {
        isUploading = false;
        _titleController.clear();
        _files = [];
      });
      TopSnackBarWiidget(context, 'Note added successfully!');
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      TopSnackBarWiidget(context, 'Failed to add note: $e');
    }

    // Update the group's last activity timestamp
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupRef.update({
      'lastActivityTimestamp': Timestamp.now(),
    });
  }

  Future<List<String>> _uploadFiles() async {
    List<String> fileUrls = [];

    for (PlatformFile file in _files!) {
      String fileName = path.basename(file.path!);
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('groups/${widget.groupId}/notes/$fileName');

      UploadTask uploadTask = storageReference.putFile(File(file.path!));

      TaskSnapshot storageSnapshot = await uploadTask;
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();
      fileUrls.add(downloadUrl);
    }

    return fileUrls;
  }

  Future<void> _updateUserPoints(String uid) async {
    try {
      // Get the LeaderBoard document for the current group
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      List<String> memberIds = List<String>.from(groupDoc['members']);

      // Ensure the user is in the members list
      if (memberIds.contains(uid)) {
        DocumentSnapshot leaderboardDoc = await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('LeaderBoard')
            .doc(uid)
            .get();

        if (leaderboardDoc.exists) {
          // Cast the data to Map<String, dynamic> to access fields
          Map<String, dynamic> data =
              leaderboardDoc.data() as Map<String, dynamic>;
          int currentPoints = data['points'] as int;

          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('LeaderBoard')
              .doc(uid)
              .update({
            'points': currentPoints + 1,
          });
        } else {
          // If the user is not yet in the leaderboard, add them with 1 point
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('LeaderBoard')
              .doc(uid)
              .set({
            'name': FirebaseAuth.instance.currentUser!.displayName ?? 'Unknown',
            'points': 1,
          });
        }
      }
    } catch (e) {
      print('Failed to update user points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Folder Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch child widgets
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: 'Title',
              onSuffixIconPressed: () {},
              showSuffixIcon: false, // Adjust as needed
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickFiles,
              child: Text('Pick Files'),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: _files != null
                  ? ListView.builder(
                      itemCount: _files!.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_files![index].name),
                        );
                      },
                    )
                  : Center(
                      child: Text('No files selected.'),
                    ),
            ),
            SizedBox(height: 16.0),
            isUploading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _uploadNote,
                    child: Text('Upload Note'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0), // Padding for left and right
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
