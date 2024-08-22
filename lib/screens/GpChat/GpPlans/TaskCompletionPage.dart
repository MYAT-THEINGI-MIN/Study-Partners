import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  List<Map<String, dynamic>> _completedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchTaskCompletionDetails();
  }

  Future<void> _fetchTaskCompletionDetails() async {
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
      List<dynamic> tasks = docSnapshot['tasks'] as List<dynamic>;

      if (widget.taskIndex < tasks.length) {
        var task = tasks[widget.taskIndex];
        List<dynamic> completed = List.from(task['completed'] ?? []);

        String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

        _completedUsers.clear();

        for (var completion in completed) {
          if (completion['uid'] == currentUserId) {
            setState(() {
              _isCompleted = true;
              _submittedImageUrl = completion['imageURL'];
            });
          }

          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(completion['uid'])
              .get();

          _completedUsers.add({
            'username': userSnapshot['username'] ?? 'Unknown',
            'profileImageUrl': userSnapshot['profileImageUrl'] ?? '',
            'imageURL': completion['imageURL'] ?? '',
            'uid': completion['uid'],
          });
        }

        _completedUsers.sort((a, b) => a['uid'] == currentUserId ? -1 : 1);
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupRef.update({
      'lastActivityTimestamp': Timestamp.now(),
    });
  }

  Future<void> _completeTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? pickedImage =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        _image = File(pickedImage.path);
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
        List<dynamic> tasks = docSnapshot['tasks'] as List<dynamic>;

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

          await _incrementUserPoints();

          setState(() {
            _isCompleted = true;
            _submittedImageUrl = downloadURL;
            _image = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task marked as complete')),
          );

          await _fetchTaskCompletionDetails();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image selected')),
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
  }

  Future<void> _incrementUserPoints() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknownUID';

    DocumentReference leaderboardRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('LeaderBoard')
        .doc(uid);

    DocumentSnapshot leaderboardSnapshot = await leaderboardRef.get();

    if (leaderboardSnapshot.exists) {
      int currentPoints = leaderboardSnapshot['points'] ?? 0;
      await leaderboardRef.update({'points': currentPoints + 1});
    } else {
      await leaderboardRef.set({
        'points': 1,
        'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
        'uid': uid,
      });
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
      List<dynamic> tasks = docSnapshot['tasks'] as List<dynamic>;

      if (widget.taskIndex < tasks.length) {
        var task = tasks[widget.taskIndex];
        List<dynamic> completed = List.from(task['completed'] ?? []);
        completed.removeWhere(
          (completion) =>
              (completion as Map<String, dynamic>)['uid'] ==
              FirebaseAuth.instance.currentUser?.uid,
        );

        tasks[widget.taskIndex] = {
          ...task,
          'completed': completed,
        };

        await docRef.update({'tasks': tasks});

        await _decrementUserPoints();

        setState(() {
          _isCompleted = false;
          _submittedImageUrl = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task completion removed')),
        );

        await _fetchTaskCompletionDetails();
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

    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupRef.update({
      'lastActivityTimestamp': Timestamp.now(),
    });
  }

  Future<void> _decrementUserPoints() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknownUID';

    DocumentReference leaderboardRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('LeaderBoard')
        .doc(uid);

    DocumentSnapshot leaderboardSnapshot = await leaderboardRef.get();

    if (leaderboardSnapshot.exists) {
      int currentPoints = leaderboardSnapshot['points'] ?? 0;
      int newPoints = currentPoints - 1;
      if (newPoints < 0) newPoints = 0;
      await leaderboardRef.update({'points': newPoints});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Completion'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 16), // Space at the top
                  if (_submittedImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Image.network(_submittedImageUrl!),
                      ),
                    ),
                  if (!_isCompleted)
                    Center(
                      child: ElevatedButton(
                        onPressed: _completeTask,
                        child: Text('Complete Task'),
                      ),
                    ),
                  if (_isCompleted)
                    Center(
                      child: ElevatedButton(
                        onPressed: _deleteTask,
                        child: Text('Remove Completion'),
                      ),
                    ),
                  const Divider(
                    thickness: 2,
                    height: 30,
                    color: Colors.deepPurple,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        'Completed Members',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  _completedUsers.isNotEmpty
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _completedUsers.map((user) {
                              return Container(
                                width: 360,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              user['profileImageUrl']),
                                          radius: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          user['username'],
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    if (user['imageURL'] != null)
                                      Image.network(
                                        user['imageURL'],
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              'No one has completed this task yet.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Color.fromARGB(255, 122, 122, 122),
                                  ),
                            ),
                          ),
                        ),
                  SizedBox(height: 16), // Space at the bottom
                ],
              ),
            ),
    );
  }
}
