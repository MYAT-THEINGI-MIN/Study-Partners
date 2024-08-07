import 'package:flutter/material.dart';
import 'package:sp_test/screens/Planner/TaskManagement.dart';
import 'package:sp_test/screens/Planner/addTaskPg.dart';
import 'package:sp_test/screens/Planner/button.dart';
import 'package:sp_test/screens/Planner/searchTask.dart';
import 'package:sp_test/screens/Planner/shareTaskPg.dart';
import 'package:sp_test/screens/Planner/taskCard.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebaseService.dart';

class PlannerPage extends StatefulWidget {
  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week; // Show week format
  FirebaseService _firebaseService = FirebaseService();
  TaskManagement _taskManagement =
      TaskManagement(); // Instantiate TaskManagement

  User? _currentUser;
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTasks();
  }

  void _getCurrentUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _currentUser = user;
          _loadTasks();
        });
      }
    });
  }

  void _loadTasks() {
    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('tasks')
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        setState(() {
          _allTasks = snapshot.docs
              .map((doc) =>
                  {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .toList();
          _filterTasks();
          print("All tasks loaded: $_allTasks");
        });
      });
    }
  }

  void _filterTasks() {
    setState(() {
      _tasks = _allTasks.where((task) {
        DateTime taskDate = DateTime.parse(task['date']);
        return isSameDay(taskDate, _selectedDay);
      }).toList();
      print("Filtered tasks for $_selectedDay: $_tasks");
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _allTasks
        .where((task) => isSameDay(DateTime.parse(task['date']), day))
        .toList();
  }

  void _deleteTask(String id) {
    _taskManagement.deleteTask(id); // Use TaskManagement to delete task
  }

  void _markTaskAsDone(String id) {
    _taskManagement
        .markTaskAsDone(id); // Use TaskManagement to mark task as done
  }

  void _markTaskAsUndone(String id) {
    _taskManagement
        .markTaskAsUndone(id); // Use TaskManagement to mark task as undone
  }

  Widget _addTaskBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10),
      margin: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  if (_currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SearchTasksPage(uid: _currentUser!.uid),
                      ),
                    ).then((_) {
                      // Reload tasks when returning from search page
                      _loadTasks();
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  if (_currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShareTasksPage(
                          uid: _currentUser!.uid,
                          selectedDay: _selectedDay,
                        ),
                      ),
                    ).then((_) {
                      // Reload tasks when returning from share page
                      _loadTasks();
                    });
                  }
                },
              ),
            ],
          ),
          myButton(
            label: 'Add Task',
            onTap: () {
              if (_currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(
                      uid: _currentUser!.uid,
                    ),
                  ),
                ).then((_) {
                  // Reload tasks when returning from add task page
                  _loadTasks();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _addTaskBar(context),
          Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _filterTasks();
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color.fromARGB(255, 137, 198, 247),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color for the header
                ),
                leftChevronIcon: Icon(Icons.chevron_left),
                rightChevronIcon: Icon(Icons.chevron_right),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade300, // Header background color
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              daysOfWeekHeight: 20.0,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: _buildEventsMarker(events.length),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Container(
            height: 5,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 20, bottom: 20),
                      decoration: BoxDecoration(
                          color: Colors.transparent, // Remove card color
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        'No tasks for the selected day',
                        style: Theme.of(context).textTheme.bodyMedium!,
                      ),
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 10),
                    decoration: BoxDecoration(
                        color: Colors.transparent, // Remove card color
                        borderRadius: BorderRadius.circular(20)),
                    child: ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
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
                          onEdit: (String id) {}, // Handle onEdit if needed
                          onUndone: _markTaskAsUndone, // Pass onUndone callback
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(int eventCount) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$eventCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
