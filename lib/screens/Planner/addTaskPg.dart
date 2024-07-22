import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
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

  void _createTask() {
    final title = _titleController.text;
    final note = _noteController.text;
    final date =
        DateTime.parse(_dateController.text); // Convert date string to DateTime
    final time = _timeController.text;
    final repeat = _selectedRepeat;
    final remind = _selectedRemind;
    final color =
        _selectedColor?.value ?? Colors.blue.value; // Save color value as int

    if (repeat == 'None') {
      _firebaseService.saveTask(
        uid: widget.uid,
        title: title,
        note: note,
        date: date,
        time: time,
        repeat: repeat,
        remind: remind,
        color: color,
      );
    } else {
      List<DateTime> repeatDates = [];

      if (repeat == 'Daily') {
        for (int i = 0; i < 30; i++) {
          repeatDates.add(date.add(Duration(days: i)));
        }
      } else if (repeat == 'Weekly') {
        for (int i = 0; i < 4; i++) {
          repeatDates.add(date.add(Duration(days: 7 * i)));
        }
      } else if (repeat == 'Monthly') {
        for (int i = 0; i < 12; i++) {
          repeatDates.add(DateTime(date.year, date.month + i, date.day));
        }
      }

      for (var repeatDate in repeatDates) {
        _firebaseService.saveTask(
          uid: widget.uid,
          title: title,
          note: note,
          date: repeatDate,
          time: time,
          repeat: repeat,
          remind: remind,
          color: color,
        );
      }
    }

    Navigator.pop(context); // Navigate back after saving task
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Task',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Task name
              InputField(
                title: "Title",
                hint: "Enter your new task",
                controller: _titleController,
              ),
              // Note
              InputField(
                title: "Note",
                hint: "Enter note for your task",
                controller: _noteController,
              ),
              // Date
              InputField(
                title: "Date",
                hint: "Select date",
                controller: _dateController,
                widget: IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    color: Colors.black,
                  ),
                  onPressed: () => _selectDate(context),
                ),
                onTap: () => _selectDate(context),
              ),
              // Time
              InputField(
                title: "Time",
                hint: "Select time",
                controller: _timeController,
                widget: IconButton(
                  icon: const Icon(
                    Icons.access_time,
                    color: Colors.black,
                  ),
                  onPressed: () => _selectTime(context),
                ),
                onTap: () => _selectTime(context),
              ),
              // Repeat
              InputField(
                title: "Repeat",
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
              // Remind
              InputField(
                title: "Remind",
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
              // Color circles row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
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
                      color: Colors.yellow.shade300,
                      isSelected: _selectedColor == Colors.yellow.shade300,
                      onTap: () {
                        setState(() {
                          _selectedColor = Colors.yellow.shade300;
                        });
                      },
                    ),
                    ColorCircle(
                      color: Colors.pink.shade300,
                      isSelected: _selectedColor == Colors.pink.shade300,
                      onTap: () {
                        setState(() {
                          _selectedColor = Colors.pink.shade300;
                        });
                      },
                    ),
                    // Create task button
                    myButton(
                      label: 'Create Task',
                      onTap: _createTask,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
