import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/Planner/taskCard.dart';

class InputField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController? controller;
  final Widget? widget;
  final VoidCallback? onTap;

  const InputField({
    Key? key,
    required this.title,
    required this.hint,
    this.controller,
    this.widget,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 226, 219, 240),
              border: Border.all(color: Colors.deepPurple, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: Theme.of(context).textTheme.bodyMedium,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onTap: onTap,
                  ),
                ),
                if (widget != null) widget!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    _searchTasks(_searchController.text);
  }

  void _searchTasks(String query) {
    if (query.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('tasks')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get()
          .then((QuerySnapshot snapshot) {
        setState(() {
          _searchResults = snapshot.docs
              .map((doc) =>
                  {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .toList();
          _groupTasksByDate();
        });
      });
    } else {
      setState(() {
        _searchResults.clear();
        _groupedTasks.clear();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Tasks'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputField(
            title: 'Search by Title',
            hint: 'Enter task title...',
            controller: _searchController,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _groupedTasks.isEmpty
                ? Center(child: Text('No tasks found'))
                : ListView.builder(
                    itemCount: _groupedTasks.keys.length,
                    itemBuilder: (context, index) {
                      String date = _groupedTasks.keys.elementAt(index);
                      List<Map<String, dynamic>> tasks = _groupedTasks[date]!;
                      return ExpansionTile(
                        title: Text(
                            DateFormat.yMMMMd().format(DateTime.parse(date))),
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
                            onDelete: _deleteTask,
                            onDone: _markTaskAsDone,
                            onEdit: (String) {},
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _deleteTask(String id) {
    if (widget.uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('tasks')
          .doc(id)
          .delete();
    }
  }

  void _markTaskAsDone(String id) {
    if (widget.uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('tasks')
          .doc(id)
          .update({'color': Colors.grey.value.toString()});
    }
  }

  void _editTask(String id) {
    // Implement editing task functionality if needed
  }
}
