import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/screens/Planner/ShareTaskSheet.dart';
import 'package:sp_test/widgets/CustomDateTextField.dart';
import 'package:sp_test/widgets/textfield.dart';

class ShareTasksPage extends StatefulWidget {
  final String uid;
  final DateTime selectedDay;

  ShareTasksPage({required this.uid, required this.selectedDay});

  @override
  _ShareTasksPageState createState() => _ShareTasksPageState();
}

class _ShareTasksPageState extends State<ShareTasksPage> {
  List<Map<String, dynamic>> _tasks = [];
  Map<String, List<Map<String, dynamic>>> _groupedTasks = {};
  TextEditingController _planNameController = TextEditingController();
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController _noteController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<DocumentSnapshot> _groups = [];
  String? _username; // Store the username

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _fetchUsername(); // Fetch the username when the page initializes
  }

  void _fetchUsername() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();

    setState(() {
      _username = userDoc['username']; // Store the username
    });
  }

  void _loadGroups() {
    FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: widget.uid)
        .get()
        .then((QuerySnapshot snapshot) {
      setState(() {
        _groups = snapshot.docs;
      });
    });
  }

  void _loadTasks() {
    if (_startDate == null || _endDate == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('tasks')
        .where('date',
            isGreaterThanOrEqualTo:
                _startDate?.toIso8601String().split('T').first)
        .where('date',
            isLessThanOrEqualTo: _endDate?.toIso8601String().split('T').first)
        .get()
        .then((QuerySnapshot snapshot) {
      setState(() {
        _tasks = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        _groupTasksByDate();
      });
    });
  }

  void _groupTasksByDate() {
    _groupedTasks.clear();
    for (var task in _tasks) {
      String date = task['date'];
      if (!_groupedTasks.containsKey(date)) {
        _groupedTasks[date] = [];
      }
      _groupedTasks[date]!.add(task);
    }
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, DateTime? initialDate) async {
    DateTime firstDate = controller == _startDateController
        ? DateTime.now()
        : (_startDate ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toIso8601String().split('T').first;
        if (controller == _startDateController) {
          _startDate = picked;
          // Ensure end date is not before the start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else if (controller == _endDateController) {
          _endDate = picked;
        }
        _loadTasks(); // Load tasks when date range is selected
      });
    }
  }

  void _removeTask(String taskId) {
    setState(() {
      _tasks.removeWhere((task) => task['id'] == taskId);
      _groupTasksByDate();
    });
  }

  void _showGroupSelectionSheet() {
    if (_planNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a plan name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tasks selected for the date range'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_username == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to fetch username. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return ShareTasksSheet(
          parentContext: context, // Pass the context
          groups: _groups,
          tasks: _tasks,
          uid: widget.uid,
          planName: _planNameController.text,
          note: _noteController.text,
          // username: _username!, // Pass the fetched username
        );
      },
    ).then((_) {
      // Clear all text fields after sharing plan
      _planNameController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _noteController.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _tasks = [];
        _groupedTasks = {};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan shared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate the total number of tasks and the length of the date range
    int totalTasks = _tasks.length;
    int dateRangeLength = _startDate != null && _endDate != null
        ? _endDate!.difference(_startDate!).inDays + 1
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Tasks'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _planNameController,
                    labelText: 'Plan Name',
                    onSuffixIconPressed: () {},
                    showSuffixIcon: false,
                  ),
                  CustomDateTextField(
                    controller: _startDateController,
                    labelText: 'Start Date',
                    onTap: () =>
                        _selectDate(context, _startDateController, _startDate),
                  ),
                  CustomDateTextField(
                    controller: _endDateController,
                    labelText: 'End Date',
                    onTap: () =>
                        _selectDate(context, _endDateController, _endDate),
                  ),
                  CustomTextField(
                    controller: _noteController,
                    labelText: 'Note',
                    onSuffixIconPressed: () {},
                    showSuffixIcon: false,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Total Tasks: $totalTasks',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Date Range Length: $dateRangeLength days',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ..._groupedTasks.entries.map((entry) {
                    String date = entry.key;
                    List<Map<String, dynamic>> tasks = entry.value;
                    return ExpansionTile(
                      title: Text(
                        DateFormat('MMMM dd, yyyy')
                            .format(DateTime.parse(date)),
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: tasks.map((task) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: const BorderSide(
                                color: Colors.deepPurple, width: 1.0),
                          ),
                          child: ListTile(
                            title: Text(
                              task['title'] ?? 'No title',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            subtitle: Text(
                              task['note'] ?? '',
                              style: const TextStyle(fontSize: 14.0),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle),
                              onPressed: () => _removeTask(task['id']),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showGroupSelectionSheet,
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
