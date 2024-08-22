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

        // Increment user points by 1
        await _updateUserPoints(1);

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

  Future<void> _updateUserPoints(int change) async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('LeaderBoard')
          .doc(currentUserId);

      DocumentSnapshot userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        int currentPoints = userSnapshot['points'] ?? 0;
        await userDoc.update({
          'points': currentPoints + change,
        });
      } else {
        await userDoc.set({
          'uid': currentUserId,
          'points': change,
          // Additional fields like name can be set here if needed
        });
      }
    } catch (e) {
      TopSnackBarWiidget(context, 'Failed to update points: $e');
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
    final Uri uri = Uri.parse(url); // Use Uri.parse() for URL parsing
    if (await canLaunchUrl(uri)) {
      // Use canLaunchUrl() instead of canLaunch()
      await launchUrl(uri); // Use launchUrl() instead of launch()
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

        // Decrement user points by 1
        await _updateUserPoints(-1);

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
        // Get the number of files in the note
        DocumentSnapshot noteSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('notes')
            .doc(noteId)
            .get();

        List<String> files = List<String>.from(noteSnapshot['files'] ?? []);

        // Remove note document from Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('notes')
            .doc(noteId)
            .delete();

        // Decrement user points by the number of files
        await _updateUserPoints(-files.length);

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
              title: const Text('Confirmation'),
              content: Text(message),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete'),
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
      shape: const RoundedRectangleBorder(
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
                leading: const Icon(Icons.add, color: Colors.blue),
                title: const Text('Add Files'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _pickAndUploadFiles(noteId);
                },
              ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Note'),
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

    Color textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey // Light blue for dark mode
        : Colors.black;

    return ListTile(
      leading: Icon(fileIcon, color: Colors.grey),
      title: Text(
        fileName,
        style: TextStyle(
          fontSize: 16,
          color: textColor, // Now applied correctly without const
        ),
      ),
      subtitle: Text(
        'Size: ${(fileUrl.length / 1024).toStringAsFixed(2)} KB',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: canDelete
          ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
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
        title: const Text('Notes'),
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
            child: const Text(
              'Add New Folder',
              style: TextStyle(color: Colors.deepPurple),
            ),
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
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  String noteId = doc.id;
                  String noteTitle = doc['title'];
                  List<dynamic> files = doc['files'] ?? [];
                  String createdBy = doc['uid'];
                  bool canDelete = currentUserId == createdBy;

                  return ExpansionTile(
                    title: GestureDetector(
                      onTap: () => _showBottomSheet(context, noteId, canDelete),
                      child: Text(
                        noteTitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    children: files
                        .map<Widget>((fileUrl) =>
                            _buildFileListTile(noteId, fileUrl, canDelete))
                        .toList(),
                  );
                }).toList(),
              );
            },
          ),
          if (isUploading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(width: 16.0),
                    Text(
                      'Uploading...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
