import 'package:flutter/material.dart';
import 'package:sp_test/screens/Planner/addTaskPg.dart';
import 'package:sp_test/screens/Planner/button.dart';
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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  FirebaseService _firebaseService = FirebaseService();

  User? _currentUser;
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
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

  List<Event> _getEventsForDay(DateTime day) {
    return _allTasks
        .where((task) => isSameDay(DateTime.parse(task['date']), day))
        .map((task) => Event(task['title']))
        .toList();
  }

  void _deleteTask(String id) {
    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('tasks')
          .doc(id)
          .delete();
    }
  }

  void _markTaskAsDone(String id) {
    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('tasks')
          .doc(id)
          .update({'color': Colors.white.value});
    }
  }

  Widget _addTaskBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMd().format(_selectedDay),
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
                Text(
                  "Today",
                  style: Theme.of(context).textTheme.bodyMedium!,
                ),
              ],
            ),
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
                      taskId: '',
                    ),
                  ),
                );
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
          TableCalendar(
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
              _focusedDay = focusedDay;
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
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left),
              rightChevronIcon: Icon(Icons.chevron_right),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return TaskCard(
                  id: task['id'],
                  title: task['title'],
                  note: task['note'],
                  time: task['time'],
                  color: task.containsKey('color') && task['color'] is String
                      ? int.parse(task['color'], radix: 16)
                      : task['color'],
                  onDelete: _deleteTask,
                  onDone: _markTaskAsDone,
                  onEdit: (String) {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;

  Event(this.title);
}

///now tasks are show//tasks card color add//task three dots added//