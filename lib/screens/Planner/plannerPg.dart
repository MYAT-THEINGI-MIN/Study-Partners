import 'package:flutter/material.dart';
import 'package:sp_test/screens/Planner/addTaskPg.dart';
import 'package:sp_test/screens/Planner/button.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebaseService.dart'; // Import the FirebaseService

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
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadTasks();
  }

  void _getCurrentUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _currentUser = user;
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
          _tasks = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      });
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
                  style: Theme.of(context).textTheme.bodySmall!,
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
                    builder: (context) => AddTaskPage(uid: _currentUser!.uid),
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
      appBar: AppBar(
        title: Text('Planner Page'),
      ),
      body: Column(
        children: [
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
          ),
          _addTaskBar(context),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  title: Text(task['title']),
                  subtitle: Text(task['note']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
