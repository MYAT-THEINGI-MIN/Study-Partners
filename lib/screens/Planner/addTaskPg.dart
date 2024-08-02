import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/Service/NotificationService.dart';
import 'package:sp_test/screens/Planner/InputField.dart';
import 'package:sp_test/screens/Planner/button.dart';
import 'package:sp_test/screens/Planner/colorCircle.dart';
import 'package:sp_test/screens/Planner/firebaseService.dart';

class AddTaskPage extends StatefulWidget {
  final String uid;
  final String? title;
  final String? description;
  final DateTime? deadline;

  const AddTaskPage({
    Key? key,
    required this.uid,
    this.title,
    this.description,
    this.deadline,
  }) : super(key: key);

  @override
  _AddTaskPageState createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  String _selectedRepeat = 'None';
  String _selectedRemind = '5 minutes before';
  Color? _selectedColor;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title ?? '');
    _noteController = TextEditingController(text: widget.description ?? '');
    _dateController = TextEditingController(
      text: widget.deadline != null
          ? DateFormat('yyyy-MM-dd').format(widget.deadline!)
          : '',
    );
    _timeController = TextEditingController();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  void _createTask() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final dateString = _dateController.text.trim();
    final timeString = _timeController.text.trim();

    if (title.isEmpty ||
        note.isEmpty ||
        dateString.isEmpty ||
        timeString.isEmpty) {
      print('Please fill in all fields.');
      return;
    }

    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateString);
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) {
        throw FormatException('Invalid time format');
      }

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1].split(' ')[0]);
      final scheduledDateTime =
          DateTime(date.year, date.month, date.day, hour, minute);

      final remindMinutes = int.parse(_selectedRemind.split(' ')[0]);
      DateTime notifyDateTime =
          scheduledDateTime.subtract(Duration(minutes: remindMinutes));

      final notificationIdBase =
          DateTime.now().millisecondsSinceEpoch % 2147483647;

      print(
          'Creating tasks and notifications for repeat option: $_selectedRepeat');

      switch (_selectedRepeat) {
        case 'Daily':
          for (int i = 0; i < 30; i++) {
            final taskDate = scheduledDateTime.add(Duration(days: i));
            print('Creating daily task for: $taskDate');
            await _firebaseService.saveTask(
              uid: widget.uid,
              title: title,
              note: note,
              date: taskDate,
              time: timeString,
              repeat: _selectedRepeat,
              remind: _selectedRemind,
              color: _selectedColor?.value ?? Colors.blue.value,
            );

            print('Scheduling notification for: $taskDate');
            await NotificationService.scheduleNotification(
              id: notificationIdBase + i,
              title: 'Task Reminder',
              body: 'Reminder for task: $title',
              scheduledDate: notifyDateTime.add(Duration(days: i)),
            );
          }
          break;

        case 'Weekly':
          for (int i = 0; i < 4; i++) {
            final taskDate = scheduledDateTime.add(Duration(days: 7 * i));
            print('Creating weekly task for: $taskDate');
            await _firebaseService.saveTask(
              uid: widget.uid,
              title: title,
              note: note,
              date: taskDate,
              time: timeString,
              repeat: _selectedRepeat,
              remind: _selectedRemind,
              color: _selectedColor?.value ?? Colors.blue.value,
            );

            print('Scheduling notification for: $taskDate');
            await NotificationService.scheduleNotification(
              id: notificationIdBase + i,
              title: 'Task Reminder',
              body: 'Reminder for task: $title',
              scheduledDate: notifyDateTime.add(Duration(days: 7 * i)),
            );
          }
          break;

        case 'Monthly':
          for (int i = 0; i < 3; i++) {
            final taskDate = DateTime(
              scheduledDateTime.year,
              scheduledDateTime.month + i,
              scheduledDateTime.day,
              scheduledDateTime.hour,
              scheduledDateTime.minute,
            );
            print('Creating monthly task for: $taskDate');
            await _firebaseService.saveTask(
              uid: widget.uid,
              title: title,
              note: note,
              date: taskDate,
              time: timeString,
              repeat: _selectedRepeat,
              remind: _selectedRemind,
              color: _selectedColor?.value ?? Colors.blue.value,
            );

            print('Scheduling notification for: $taskDate');
            await NotificationService.scheduleNotification(
              id: notificationIdBase + i,
              title: 'Task Reminder',
              body: 'Reminder for task: $title',
              scheduledDate: notifyDateTime.add(Duration(days: 30 * i)),
            );
          }
          break;

        case 'None':
          print('Creating single task for: $scheduledDateTime');
          await _firebaseService.saveTask(
            uid: widget.uid,
            title: title,
            note: note,
            date: scheduledDateTime,
            time: timeString,
            repeat: _selectedRepeat,
            remind: _selectedRemind,
            color: _selectedColor?.value ?? Colors.blue.value,
          );

          print('Scheduling single notification for: $scheduledDateTime');
          await NotificationService.scheduleNotification(
            id: notificationIdBase,
            title: 'Task Reminder',
            body: 'Reminder for task: $title',
            scheduledDate: notifyDateTime,
          );
          break;
      }

      print('Tasks saved to Firestore and notifications scheduled.');
      Navigator.pop(context);
    } catch (e) {
      print('Error creating task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Add New Task', style: Theme.of(context).textTheme.bodyMedium),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InputField(
                    hint: "Enter task title",
                    controller: _titleController,
                  ),
                  InputField(
                    hint: "Enter note for your task",
                    controller: _noteController,
                  ),
                  InputField(
                    hint: "Select date",
                    controller: _dateController,
                    widget: IconButton(
                      icon:
                          const Icon(Icons.calendar_today, color: Colors.black),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  InputField(
                    hint: "Select time",
                    controller: _timeController,
                    widget: IconButton(
                      icon: const Icon(Icons.access_time, color: Colors.black),
                      onPressed: () => _selectTime(context),
                    ),
                  ),
                  InputField(
                    hint: "Select repeat",
                    controller: null,
                    widget: DropdownButton<String>(
                      value: _selectedRepeat,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRepeat = newValue!;
                        });
                      },
                      items: <String>['None', 'Daily', 'Weekly', 'Monthly']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(color: Colors.deepPurple)),
                        );
                      }).toList(),
                    ),
                  ),
                  InputField(
                    hint: "Select Remind Time",
                    controller: null,
                    widget: DropdownButton<String>(
                      value: _selectedRemind,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRemind = newValue!;
                        });
                      },
                      items: <String>[
                        '5 minutes before',
                        '10 minutes before',
                        '15 minutes before',
                        '20 minutes before'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(color: Colors.deepPurple)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ColorCircle(
                        color: Colors.blue.shade300,
                        isSelected: _selectedColor == Colors.blue.shade300,
                        onTap: () {
                          setState(() {
                            _selectedColor = Colors.blue.shade300;
                          });
                        },
                      ),
                      ColorCircle(
                        color: Colors.red.shade300,
                        isSelected: _selectedColor == Colors.red.shade300,
                        onTap: () {
                          setState(() {
                            _selectedColor = Colors.red.shade300;
                          });
                        },
                      ),
                      ColorCircle(
                        color: Colors.green.shade300,
                        isSelected: _selectedColor == Colors.green.shade300,
                        onTap: () {
                          setState(() {
                            _selectedColor = Colors.green.shade300;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  myButton(
                    label: "Create Task",
                    onTap: _createTask,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
