import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/Planner/InputField.dart';
import 'package:sp_test/screens/Planner/TaskManagement.dart';
import 'package:sp_test/screens/Planner/taskCard.dart';

class SearchTasksPage extends StatefulWidget {
  final String uid;

  const SearchTasksPage({required this.uid, Key? key}) : super(key: key);

  @override
  _SearchTasksPageState createState() => _SearchTasksPageState();
}

class _SearchTasksPageState extends State<SearchTasksPage> {
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, List<Map<String, dynamic>>> _groupedTasks = {};
  TextEditingController _searchController = TextEditingController();
  final TaskManagement _taskManagement = TaskManagement();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Tasks'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
              hint: 'Enter task title...',
              controller: _searchController,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.uid)
                    .collection('tasks')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No tasks found'));
                  }

                  // Filter tasks based on the search query
                  _searchResults = snapshot.data!.docs
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? '';
                        return title
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      })
                      .map((doc) =>
                          {'id': doc.id, ...doc.data() as Map<String, dynamic>})
                      .toList();

                  _groupTasksByDate();

                  return _groupedTasks.isEmpty
                      ? Center(child: Text('No tasks found'))
                      : ListView.builder(
                          itemCount: _groupedTasks.keys.length,
                          itemBuilder: (context, index) {
                            String date = _groupedTasks.keys.elementAt(index);
                            List<Map<String, dynamic>> tasks =
                                _groupedTasks[date]!;
                            return ExpansionTile(
                              title: Text(DateFormat.yMMMMd()
                                  .format(DateTime.parse(date))),
                              children: tasks.map((task) {
                                return TaskCard(
                                  id: task['id'],
                                  title: task['title'],
                                  note: task['note'],
                                  time: task['time'],
                                  color: task.containsKey('color') &&
                                          task['color'] is String
                                      ? int.parse(task['color'], radix: 16)
                                      : task['color'],
                                  onDelete: _taskManagement.deleteTask,
                                  onDone: _taskManagement.markTaskAsDone,
                                  onEdit: _editTask,
                                  onUndone: _taskManagement.markTaskAsUndone,
                                );
                              }).toList(),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _groupTasksByDate() {
    _groupedTasks.clear();
    for (var task in _searchResults) {
      String date = task['date'];
      if (!_groupedTasks.containsKey(date)) {
        _groupedTasks[date] = [];
      }
      _groupedTasks[date]!.add(task);
    }
  }

  void _editTask(String id) {
    // Implement editing task functionality if needed
  }
}
