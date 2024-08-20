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

        for (var completion in completed) {
          if (completion['uid'] == currentUserId) {
            setState(() {
              _isCompleted = true;
              _submittedImageUrl = completion['imageURL'];
            });
          }

          // Fetch additional user details
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

        // Sort the current user to the top
        _completedUsers.sort((a, b) => a['uid'] == currentUserId ? -1 : 1);
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // Update the group's last activity timestamp
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupRef.update({
      'lastActivityTimestamp': Timestamp.now(),
    });
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

          // Increment user's points in the LeaderBoard
          await _incrementUserPoints();

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

  Future<void> _incrementUserPoints() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknownUID';

    DocumentReference leaderboardRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('LeaderBoard')
        .doc(uid);

    DocumentSnapshot leaderboardSnapshot = await leaderboardRef.get();

    if (leaderboardSnapshot.exists) {
      // User exists in the leaderboard, increment points
      int currentPoints = leaderboardSnapshot['points'] ?? 0;
      await leaderboardRef.update({'points': currentPoints + 1});
    } else {
      // User does not exist, create entry with 1 point
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

        // Decrement user's points in the LeaderBoard
        await _decrementUserPoints();

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

    // Update the group's last activity timestamp
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
      // User exists in the leaderboard, decrement points
      int currentPoints = leaderboardSnapshot['points'] ?? 0;
      int newPoints = currentPoints - 1;
      if (newPoints < 0) newPoints = 0; // Ensure points don't go negative
      await leaderboardRef.update({'points': newPoints});
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(0), // Remove padding
          child: Container(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit
                    .contain, // Ensure the image fits within the container
              ),
            ),
          ),
        );
      },
    );
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
                children: [
                  if (_isCompleted)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Your Submission',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showFullImage(_submittedImageUrl!);
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(_submittedImageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _deleteTask,
                          child: Text('Remove Completion'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Submit Your Completion',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        _image != null
                            ? Image.file(
                                _image!,
                                height: 200,
                              )
                            : SizedBox(height: 200),
                        TextButton(
                          onPressed: _pickImage,
                          child: Text('Select Image'),
                        ),
                        ElevatedButton(
                          onPressed: _completeTask,
                          child: Text('Mark as Complete'),
                        ),
                      ],
                    ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Completed Users',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _completedUsers.length,
                    itemBuilder: (context, index) {
                      var user = _completedUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(user['profileImageUrl']),
                        ),
                        title: Text(user['username']),
                        onTap: () => _showFullImage(user['imageURL']),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
