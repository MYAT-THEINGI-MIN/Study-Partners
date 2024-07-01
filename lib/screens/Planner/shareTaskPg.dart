import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareTasksPage extends StatefulWidget {
  final String uid;
  final DateTime selectedDay;

  ShareTasksPage({required this.uid, required this.selectedDay});

  @override
  _ShareTasksPageState createState() => _ShareTasksPageState();
}

class _ShareTasksPageState extends State<ShareTasksPage> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _selectedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('tasks')
        .where('date',
            isEqualTo: widget.selectedDay.toIso8601String().split('T').first)
        .get()
        .then((QuerySnapshot snapshot) {
      setState(() {
        _tasks = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    });
  }

  void _shareTasks() {
    if (_selectedTasks.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No tasks selected')));
      return;
    }

    // Implement sharing logic here, e.g., sending a sharing request to the receiver
    // For demonstration, we'll just print the selected tasks
    print('Selected tasks to share: $_selectedTasks');

    // Clear selected tasks after sharing
    setState(() {
      _selectedTasks.clear();
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Tasks shared successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Tasks'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final isSelected = _selectedTasks.contains(task);

                return ListTile(
                  title: Text(task['title']),
                  subtitle: Text(task['note']),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedTasks.add(task);
                        } else {
                          _selectedTasks.remove(task);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _shareTasks,
            child: Text('Share Selected Tasks'),
          ),
        ],
      ),
    );
  }
}
