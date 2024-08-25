import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Import for color wheel
import 'package:sp_test/Service/NotificationService.dart';
import 'package:sp_test/screens/Planner/InputField.dart';
import 'package:sp_test/screens/Planner/button.dart';
import 'package:sp_test/screens/Planner/colorCircle.dart';
import 'package:sp_test/screens/Planner/firebaseService.dart';
import 'package:sp_test/widgets/CustomDateTextField.dart';
import 'package:sp_test/widgets/customTimeTextField.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

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
      TopSnackBarWiidget(context, 'Please Fill Necessary Data');
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

      // Handle different repeat cases
      switch (_selectedRepeat) {
        case 'Daily':
          for (int i = 0; i < 30; i++) {
            final taskDate = scheduledDateTime.add(Duration(days: i));
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

            await NotificationService.scheduleNotification(
              id: notificationIdBase + i,
              title: 'Task Reminder',
              body: 'Reminder for task: $title',
              scheduledDate: notifyDateTime.add(Duration(days: 7 * i)),
            );
          }
          break;

        case 'Monthly':
          DateTime currentMonth = DateTime(scheduledDateTime.year,
              scheduledDateTime.month, scheduledDateTime.day);
          while (currentMonth.year == scheduledDateTime.year) {
            await _firebaseService.saveTask(
              uid: widget.uid,
              title: title,
              note: note,
              date: currentMonth,
              time: timeString,
              repeat: _selectedRepeat,
              remind: _selectedRemind,
              color: _selectedColor?.value ?? Colors.blue.value,
            );
            await NotificationService.scheduleNotification(
              id: notificationIdBase + currentMonth.month,
              title: 'Task Reminder',
              body: 'Reminder for task: $title',
              scheduledDate: notifyDateTime.add(Duration(
                  days: 30 * (currentMonth.month - scheduledDateTime.month))),
            );
            currentMonth = DateTime(
                currentMonth.year, currentMonth.month + 1, currentMonth.day);
          }
          break;

        case 'None':
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
          await NotificationService.scheduleNotification(
            id: notificationIdBase,
            title: 'Task Reminder',
            body: 'Reminder for task: $title',
            scheduledDate: notifyDateTime,
          );
          break;
      }

      // Show success snack bar
      TopSnackBarWiidget(context, 'Task Created Successfully');

      // Clear the input fields
      _titleController.clear();
      _noteController.clear();
      _dateController.clear();
      _timeController.clear();
      setState(() {
        _selectedColor = Colors.blue; // Reset to default color
        _selectedRepeat = 'None'; // Reset repeat option
        _selectedRemind = '5 minutes before'; // Reset remind option
      });

      Navigator.pop(context); // Return to the previous screen
    } catch (e) {
      print('Error creating task: $e');
    }
  }

  void _openColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Task Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor ?? Colors.blue,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                    hint: "Enter task note",
                    controller: _noteController,
                  ),
                  CustomDateTextField(
                    controller: _dateController,
                    onTap: () => _selectDate(context),
                    labelText: 'Select Date',
                  ),
                  CustomTimeTextField(
                    controller: _timeController,
                    onTap: () => _selectTime(context),
                    labelText: 'Select Time',
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Repeat:',
                          style: Theme.of(context).textTheme.bodyMedium),
                      DropdownButton<String>(
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
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remind:',
                          style: Theme.of(context).textTheme.bodyMedium),
                      DropdownButton<String>(
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
                          '30 minutes before'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('Task Color:',
                          style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _openColorPicker(context),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _selectedColor ?? Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createTask,
                            child: const Text('Add Task'),
                          ),
                        ),
                      ],
                    ),
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
