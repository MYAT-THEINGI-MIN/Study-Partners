import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
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

  Future<void> _shareTasks() async {
    if (_tasks.isEmpty || _planNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please complete all fields and select tasks')));
      return;
    }

    final planName = _planNameController.text;
    final note = _noteController.text;

    // Create a new plan document with the selected tasks
    final planRef = FirebaseFirestore.instance
        .collection('groups')
        .doc('your-group-id')
        .collection('plans')
        .doc();
    await planRef.set({
      'planName': planName,
      'uid': widget.uid,
      'username':
          'dummy_username', // Replace with actual username fetching logic
      'note': note,
      'tasks': _tasks
          .map((task) => {
                'title': task['title'],
                'deadline': task['date'],
                'completed': [] // Initialize with empty completed list
              })
          .toList(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Tasks shared successfully!')));
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
        title: Text('Share Tasks'),
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
                  SizedBox(height: 8.0),
                  Text(
                    'Total Tasks: $totalTasks',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Date Range Length: $dateRangeLength days',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CustomTextField(
                    controller: _noteController,
                    labelText: 'Note',
                    onSuffixIconPressed:
                        () {}, // No action needed for this field
                    showSuffixIcon: false,
                  ),
                  SizedBox(height: 10),
                  _groupedTasks.isEmpty
                      ? Center(child: Text('No tasks found'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _groupedTasks.keys.length,
                          itemBuilder: (context, index) {
                            String date = _groupedTasks.keys.elementAt(index);
                            List<Map<String, dynamic>> tasks =
                                _groupedTasks[date]!;
                            return ExpansionTile(
                              title: Text(DateFormat.yMMMMd()
                                  .format(DateTime.parse(date))),
                              children: tasks.map((task) {
                                return Container(
                                  width: screenWidth -
                                      40, // Adjusted width for card
                                  margin: EdgeInsets.symmetric(
                                      vertical: 4.0), // Reduced margin
                                  padding: const EdgeInsets.all(
                                      12.0), // Adjusted padding
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade100,
                                    borderRadius: BorderRadius.circular(8.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4.0,
                                        spreadRadius: 2.0,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task['title'],
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.cancel),
                                            onPressed: () =>
                                                _removeTask(task['id']),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(task['note'] ?? ''),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: _shareTasks,
                child: Text('Share'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
