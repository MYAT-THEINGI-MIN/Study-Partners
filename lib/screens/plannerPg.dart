import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlannerPage extends StatefulWidget {
  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Task>> _tasks = {};
  bool _isTaskCardVisible = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildTableCalendar(),
          _buildTasksContainer(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Container(height: 50.0),
      ),
    );
  }

  Widget _buildTableCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _selectedDay,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _isTaskCardVisible = true;
        });
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
      ),
      eventLoader: (day) {
        return _tasks[day] ?? [];
      },
    );
  }

  Widget _buildTasksContainer() {
    List<Task> tasks = _getTasksForDay(_selectedDay);

    return Visibility(
      visible: _isTaskCardVisible,
      child: Positioned(
        left: 0,
        right: 0,
        top: 80.0,
        bottom: 0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            margin: EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 4.0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tasks for ${DateFormat.yMMMd().format(_selectedDay)}',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromRGBO(156, 39, 176, 1),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isTaskCardVisible = false;
                              });
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: tasks.isNotEmpty
                            ? ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  Task task = tasks[index];
                                  double completionPercent =
                                      (task.completionPercent ?? 0) / 100;

                                  return Dismissible(
                                    key: UniqueKey(),
                                    background: Container(color: Colors.red),
                                    onDismissed: (direction) {
                                      _deleteTask(_selectedDay, index);
                                    },
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: task.isDone,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            task.isDone = value ?? false;
                                            _saveTasks();
                                          });
                                        },
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Container(
                                            width: 30,
                                            height: 30,
                                            child: Stack(
                                              children: [
                                                CircularProgressIndicator(
                                                  value: completionPercent,
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.green,
                                                  ),
                                                ),
                                                Center(
                                                  child: Text(
                                                    '${(task.completionPercent ?? 0).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        _showTaskDetails(
                                            task, _selectedDay, index);
                                      },
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  "Make some study plans.",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      onPressed: () => _addTask(),
                      child: Icon(Icons.add),
                      backgroundColor: Colors.purple.shade100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasks[day] ?? [];
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) {
        return AddTaskDialog(
          onTaskAdded: (task) {
            setState(() {
              if (_tasks[_selectedDay] == null) {
                _tasks[_selectedDay] = [];
              }
              _tasks[_selectedDay]!.add(task);
              _saveTasks();
            });
          },
        );
      },
    );
  }

  void _deleteTask(DateTime day, int index) {
    setState(() {
      _tasks[day]?.removeAt(index);
      _saveTasks();
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final Map<String, dynamic> decodedTasks = jsonDecode(tasksString);
      final Map<DateTime, List<Task>> loadedTasks = {};
      decodedTasks.forEach((key, value) {
        final DateTime date = DateTime.parse(key);
        final List<Task> tasksList =
            (value as List).map((task) => Task.fromJson(task)).toList();
        loadedTasks[date] = tasksList;
      });
      setState(() {
        _tasks = loadedTasks;
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encodedTasks = {};
    _tasks.forEach((key, value) {
      encodedTasks[key.toIso8601String()] =
          value.map((task) => task.toJson()).toList();
    });
    final String tasksString = jsonEncode(encodedTasks);
    await prefs.setString('tasks', tasksString);
  }

  void _showTaskDetails(Task task, DateTime day, int index) {
    String newTitle = task.title;
    double completionPercent = task.completionPercent ?? 0.0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return FractionallySizedBox(
              widthFactor: 1.0,
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _deleteTask(day, index);
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Task Details',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Text('Title:'),
                    TextFormField(
                      initialValue: task.title,
                      onChanged: (value) {
                        newTitle = value;
                      },
                    ),
                    SizedBox(height: 10.0),
                    Text('Completion Percentage:'),
                    Slider(
                      value: completionPercent,
                      onChanged: (value) {
                        modalSetState(() {
                          completionPercent = value;
                        });
                      },
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '$completionPercent%',
                    ),
                    SizedBox(height: 20.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          task.title = newTitle;
                          task.completionPercent = completionPercent;
                          task.isDone = completionPercent == 100;
                          _saveTasks();
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class Task {
  String title;
  bool isDone;
  double? completionPercent;

  Task({required this.title, this.isDone = false, this.completionPercent});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isDone: json['isDone'],
      completionPercent: json['completionPercent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isDone': isDone,
      'completionPercent': completionPercent,
    };
  }
}

class AddTaskDialog extends StatefulWidget {
  final Function(Task) onTaskAdded;

  AddTaskDialog({required this.onTaskAdded});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Task title',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final task = Task(title: _controller.text);
            widget.onTaskAdded(task);
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
