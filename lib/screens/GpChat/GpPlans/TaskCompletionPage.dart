import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TaskCompletionPage extends StatefulWidget {
  final String groupId;
  final String planId;
  final int taskIndex;

  TaskCompletionPage({
    required this.groupId,
    required this.planId,
    required this.taskIndex,
  });

  @override
  _TaskCompletionPageState createState() => _TaskCompletionPageState();
}

class _TaskCompletionPageState extends State<TaskCompletionPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isCompleted = false;
  String? _submittedImageUrl;

  @override
  void initState() {
    super.initState();
    _checkIfTaskCompleted();
  }

  Future<void> _checkIfTaskCompleted() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('plans')
          .doc(widget.planId);

      DocumentSnapshot docSnapshot = await docRef.get();
      List<dynamic> tasks = docSnapshot['tasks'];

      if (widget.taskIndex < tasks.length) {
        var task = tasks[widget.taskIndex];
        List<dynamic> completed = List.from(task['completed'] ?? []);
        var userCompletion = completed.firstWhere(
          (completion) =>
              completion['uid'] == FirebaseAuth.instance.currentUser?.uid,
          orElse: () => null,
        );

        if (userCompletion != null) {
          setState(() {
            _isCompleted = true;
            _submittedImageUrl = userCompletion['imageURL'];
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _completeTask() async {
    if (_image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference firebaseStorageRef =
            FirebaseStorage.instance.ref().child('completed_tasks/$fileName');
        UploadTask uploadTask = firebaseStorageRef.putFile(_image!);
        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadURL = await taskSnapshot.ref.getDownloadURL();

        DocumentReference docRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('plans')
            .doc(widget.planId);

        DocumentSnapshot docSnapshot = await docRef.get();
        List<dynamic> tasks = docSnapshot['tasks'];

        if (widget.taskIndex < tasks.length) {
          var task = tasks[widget.taskIndex];
          List<dynamic> completed = List.from(task['completed'] ?? []);
          completed.add({
            'imageURL': downloadURL,
            'uid': FirebaseAuth.instance.currentUser?.uid ?? 'unknownUID',
          });

          tasks[widget.taskIndex] = {
            ...task,
            'completed': completed,
          };

          await docRef.update({'tasks': tasks});
          setState(() {
            _isCompleted = true;
            _submittedImageUrl = downloadURL;
            _image = null; // Clear the local image file after uploading
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task marked as complete')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete task')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
    }
  }

  Future<void> _deleteTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('plans')
          .doc(widget.planId);

      DocumentSnapshot docSnapshot = await docRef.get();
      List<dynamic> tasks = docSnapshot['tasks'];

      if (widget.taskIndex < tasks.length) {
        var task = tasks[widget.taskIndex];
        List<dynamic> completed = List.from(task['completed'] ?? []);
        completed.removeWhere(
          (completion) =>
              completion['uid'] == FirebaseAuth.instance.currentUser?.uid,
        );

        tasks[widget.taskIndex] = {
          ...task,
          'completed': completed,
        };

        await docRef.update({'tasks': tasks});
        setState(() {
          _isCompleted = false;
          _submittedImageUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task completion removed')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove task completion')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Task'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              CircularProgressIndicator()
            else ...[
              if (!_isCompleted && _submittedImageUrl == null)
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick Image'),
                ),
              if (_image != null) Image.file(_image!),
              if (_isCompleted && _submittedImageUrl != null)
                Image.network(_submittedImageUrl!),
              SizedBox(height: 20),
              if (_isCompleted && _submittedImageUrl != null)
                ElevatedButton(
                  onPressed: _deleteTask,
                  child: Text('Delete Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                )
              else if (_image != null && !_isCompleted)
                ElevatedButton(
                  onPressed: _completeTask,
                  child: Text('Complete Task'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
