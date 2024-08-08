import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/GpChat/Notes/AddNewFolderNotePage.dart';
import 'package:sp_test/widgets/topSnackBar.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class NotePage extends StatefulWidget {
  final String groupId;

  NotePage({required this.groupId});

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  bool isUploading = false;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _pickAndUploadFiles(String noteId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx'],
    );

    if (result != null) {
      setState(() {
        isUploading = true;
      });

      try {
        List<String> fileUrls = await _uploadFiles(result.files, noteId);

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('notes')
            .doc(noteId)
            .update({
          'files': FieldValue.arrayUnion(fileUrls),
        });

        setState(() {
          isUploading = false;
        });
        TopSnackBarWiidget(context, 'File added successfully!');
      } catch (e) {
        setState(() {
          isUploading = false;
        });
        TopSnackBarWiidget(context, 'Failed to add files: $e');
      }
    }
  }

  Future<List<String>> _uploadFiles(
      List<PlatformFile> files, String noteId) async {
    List<String> fileUrls = [];

    for (PlatformFile file in files) {
      String fileName = path.basename(file.path!);
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('groups/${widget.groupId}/notes/$noteId/$fileName');

      UploadTask uploadTask = storageReference.putFile(File(file.path!));

      TaskSnapshot storageSnapshot = await uploadTask;
      String downloadUrl = await storageSnapshot.ref.getDownloadURL();
      fileUrls.add(downloadUrl);
    }

    return fileUrls;
  }

  Future<void> _openFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _deleteFile(String noteId, String fileUrl) async {
    bool confirmed = await _showConfirmationDialog(
        'Are you sure you want to delete this file?');
    if (confirmed) {
      try {
        // Remove file reference from Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('notes')
            .doc(noteId)
            .update({
          'files': FieldValue.arrayRemove([fileUrl]),
        });

        // Remove file from Firebase Storage
        await FirebaseStorage.instance.refFromURL(fileUrl).delete();
        TopSnackBarWiidget(context, 'File deleted successfully!');
      } catch (e) {
        TopSnackBarWiidget(context, 'Failed to delete file: $e');
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    bool confirmed = await _showConfirmationDialog(
        'Are you sure you want to delete this note?');
    if (confirmed) {
      try {
        // Remove note document from Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('notes')
            .doc(noteId)
            .delete();

        TopSnackBarWiidget(context, 'Note deleted successfully!');
      } catch (e) {
        TopSnackBarWiidget(context, 'Failed to delete note: $e');
      }
    }
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirmation'),
              content: Text(message),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false; // In case the dialog is dismissed, return false
  }

  void _showBottomSheet(BuildContext context, String noteId, bool canDelete) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.add, color: Colors.blue),
                title: Text('Add Files'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _pickAndUploadFiles(noteId);
                },
              ),
              if (canDelete)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Note'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    _deleteNote(noteId);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileListTile(String noteId, String fileUrl, bool canDelete) {
    String fileName = fileUrl.split('/').last;
    IconData fileIcon;

    if (fileName.endsWith('.pdf')) {
      fileIcon = Icons.picture_as_pdf;
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      fileIcon = Icons.slideshow;
    } else {
      fileIcon = Icons.insert_drive_file;
    }

    return ListTile(
      leading: Icon(fileIcon, color: Colors.grey),
      title: Text(
        fileName,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        'Size: ${(fileUrl.length / 1024).toStringAsFixed(2)} KB',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: canDelete
          ? IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteFile(noteId, fileUrl),
            )
          : null,
      onTap: () => _openFile(fileUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddNewFolderNotePage(groupId: widget.groupId),
                ),
              );
            },
            child: Text(
              'Add New Folder',
              style: TextStyle(color: Colors.deepPurple),
            ),
            // style: ElevatedButton.styleFrom(
            //   backgroundColor: Colors.white, // Background color
            // ),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('notes')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final notes = snapshot.data!.docs;

              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  var note = notes[index];
                  var noteId = note.id;
                  var title = note['title'];
                  var files = List<String>.from(note['files'] ?? []);
                  var creatorUid = note['uid'];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(title),
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () => _showBottomSheet(
                                context, noteId, creatorUid == currentUserId),
                          ),
                        ],
                      ),
                      children: files
                          .map((fileUrl) => _buildFileListTile(
                              noteId, fileUrl, creatorUid == currentUserId))
                          .toList(),
                    ),
                  );
                },
              );
            },
          ),
          if (isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
