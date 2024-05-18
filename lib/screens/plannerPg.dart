import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  _PlannerHomePageState createState() => _PlannerHomePageState();
}

class _PlannerHomePageState extends State<PlannerPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<String>> _events = {};
  TextEditingController _eventController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _events = Map<DateTime, List<String>>.from(
          prefs.getStringList('events')?.asMap() ?? {});
    });
  }

  _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'events',
        _events.entries
            .map((entry) =>
                '${entry.key.toIso8601String()}:${entry.value.join(',')}')
            .toList());
  }

  _addEvent(String event) {
    setState(() {
      if (_events[_selectedDay] != null) {
        _events[_selectedDay]!.add(event);
      } else {
        _events[_selectedDay] = [event];
      }
      _saveEvents();
      _eventController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School Planner'),
      ),
      body: Column(
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
              return _events[day] ?? [];
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          ..._events[_selectedDay]
                  ?.map((event) => ListTile(title: Text(event))) ??
              [],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Event'),
        content: TextField(
          controller: _eventController,
          decoration: InputDecoration(hintText: 'Enter event name'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              if (_eventController.text.isEmpty) return;
              _addEvent(_eventController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
