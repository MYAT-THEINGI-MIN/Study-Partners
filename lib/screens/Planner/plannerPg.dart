import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({Key? key}) : super(key: key);

  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  TextEditingController _eventController = TextEditingController();
  TimeOfDay? _selectedTime;
  int _completionPercent = 0;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents();
  }

  Future<void> _getCurrentUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      // If no user is logged in, you can handle redirect or login logic here.
    } else {
      setState(() {
        _currentUser = user;
      });
      await _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    if (_currentUser == null) return;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users') // Collection for users
          .doc(_currentUser!.uid) // Document ID is the user's ID
          .collection('tasks') // Subcollection for tasks under the user
          .get();
      Map<DateTime, List<Map<String, dynamic>>> loadedEvents = {};

      querySnapshot.docs.forEach((doc) {
        DateTime date = (doc['date'] as Timestamp).toDate();
        String eventName = doc['name'];
        TimeOfDay? eventTime;
        if (doc['alarmTime'] != null) {
          eventTime = TimeOfDay(
            hour: doc['alarmTime']['hour'],
            minute: doc['alarmTime']['minute'],
          );
        }
        int completionPercent = doc['completionPercent'] ?? 0;

        DateTime roundedDate = DateTime(date.year, date.month, date.day);

        if (!loadedEvents.containsKey(roundedDate)) {
          loadedEvents[roundedDate] = [];
        }
        loadedEvents[roundedDate]!.add({
          'id': doc.id,
          'name': eventName,
          'time': eventTime,
          'completionPercent': completionPercent,
        });
      });

      setState(() {
        _events = loadedEvents;
      });
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  Future<void> _saveEvent(DateTime date, String event, TimeOfDay? time,
      int completionPercent) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users') // Collection for users
          .doc(_currentUser!.uid) // Document ID is the user's ID
          .collection('tasks') // Subcollection for tasks under the user
          .add({
        'date': Timestamp.fromDate(date),
        'name': event,
        'alarmTime':
            time != null ? {'hour': time.hour, 'minute': time.minute} : null,
        'completionPercent': completionPercent,
      });
      // Refresh events after saving
      await _loadEvents();
    } catch (e) {
      print('Error saving event: $e');
    }
  }

  Future<void> _updateEvent(String id, DateTime date, String event,
      TimeOfDay? time, int completionPercent) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users') // Collection for users
          .doc(_currentUser!.uid) // Document ID is the user's ID
          .collection('tasks') // Subcollection for tasks under the user
          .doc(id) // Document ID of the event
          .update({
        'date': Timestamp.fromDate(date),
        'name': event,
        'alarmTime':
            time != null ? {'hour': time.hour, 'minute': time.minute} : null,
        'completionPercent': completionPercent,
      });
      // Refresh events after updating
      await _loadEvents();
    } catch (e) {
      print('Error updating event: $e');
    }
  }

  Future<void> _deleteEvent(String id) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users') // Collection for users
          .doc(_currentUser!.uid) // Document ID is the user's ID
          .collection('tasks') // Subcollection for tasks under the user
          .doc(id) // Document ID of the event
          .delete();
      // Refresh events after deleting
      await _loadEvents();
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  void _addEvent(String event, TimeOfDay? time, int completionPercent) {
    DateTime roundedDate =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    // Save event for the selected day
    _saveEvent(roundedDate, event, time, completionPercent);

    _eventController.clear();
    setState(() {
      _completionPercent = 0;
      _selectedTime = null;
    });
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School Planner'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _selectedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              eventLoader: (day) {
                DateTime roundedDate = DateTime(day.year, day.month, day.day);
                return _events[roundedDate] ?? [];
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              availableCalendarFormats: const {
                CalendarFormat.week: 'Week',
              },
              calendarStyle: CalendarStyle(
                markersAlignment: Alignment.bottomCenter,
                todayDecoration: BoxDecoration(
                  color: Colors.deepPurple.shade400,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(color: Colors.white),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekendStyle: TextStyle(color: Colors.red),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            SizedBox(height: 8.0),
            Container(
              height: 300.0, // Adjust height as needed
              child: ListView.builder(
                itemCount: (_events[DateTime(_selectedDay.year,
                            _selectedDay.month, _selectedDay.day)] ??
                        [])
                    .length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> event = (_events[DateTime(
                          _selectedDay.year,
                          _selectedDay.month,
                          _selectedDay.day)] ??
                      [])[index];

                  if (event == null || !event.containsKey('name')) {
                    return SizedBox
                        .shrink(); // Skip rendering if event is null or doesn't have a name
                  }

                  String eventTime = event['time'] != null
                      ? '${event['time'].hour}:${event['time'].minute.toString().padLeft(2, '0')}'
                      : '';
                  int completionPercent = event['completionPercent'] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple[150],
                          child: Text(
                            '$completionPercent%',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 49, 49, 49),
                            ),
                          ),
                        ),
                        title: Text(event['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eventTime.isNotEmpty) Text('Time: $eventTime'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditEventDialog(
                                context,
                                event['id'],
                                event['name'],
                                event['time'],
                                completionPercent,
                              );
                            } else if (value == 'delete') {
                              _deleteEvent(event['id']);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return {'Edit', 'Delete'}.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice.toLowerCase(),
                                child: Text(choice),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    _eventController.clear();
    _selectedTime = null;
    _completionPercent = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _eventController,
                    decoration: InputDecoration(hintText: 'Enter event name'),
                  ),
                  Row(
                    children: [
                      Text(
                          "Alarm Time: ${_selectedTime != null ? _selectedTime!.format(context) : 'None'}"),
                      IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () => _selectTime(context),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("Completion %: "),
                      Expanded(
                        child: Slider(
                          value: _completionPercent.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 10,
                          label: _completionPercent.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _completionPercent = value.toInt();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                  _eventController.clear();
                  _selectedTime = null;
                  _completionPercent = 0;
                },
              ),
              TextButton(
                child: Text('Add'),
                onPressed: () {
                  if (_eventController.text.isEmpty) return;
                  _addEvent(
                    _eventController.text,
                    _selectedTime,
                    _completionPercent,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditEventDialog(
      BuildContext context,
      String eventId,
      String currentName,
      TimeOfDay? currentTime,
      int currentCompletionPercent) {
    _eventController.text = currentName;
    _selectedTime = currentTime;
    _completionPercent = currentCompletionPercent;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _eventController,
                    decoration: InputDecoration(hintText: 'Enter event name'),
                  ),
                  Row(
                    children: [
                      Text(
                          "Alarm Time: ${_selectedTime != null ? _selectedTime!.format(context) : 'None'}"),
                      IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () => _selectTime(context),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("Completion %: "),
                      Expanded(
                        child: Slider(
                          value: _completionPercent.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 10,
                          label: _completionPercent.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _completionPercent = value.toInt();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () {
                  if (_eventController.text.isEmpty) return;
                  _updateEvent(
                    eventId,
                    _selectedDay,
                    _eventController.text,
                    _selectedTime,
                    _completionPercent,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PlannerPage(),
  ));
}
