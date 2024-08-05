import 'package:flutter/material.dart';

class SelectSubjectWidget extends StatefulWidget {
  final List<String> predefinedSubjects;
  final List<String> selectedSubjects;
  final Function(List<String>) onSubjectsChanged;

  const SelectSubjectWidget({
    Key? key,
    required this.predefinedSubjects,
    required this.selectedSubjects,
    required this.onSubjectsChanged,
  }) : super(key: key);

  @override
  _SelectSubjectWidgetState createState() => _SelectSubjectWidgetState();
}

class _SelectSubjectWidgetState extends State<SelectSubjectWidget> {
  late List<String> _predefinedSubjects;
  late List<String> _selectedSubjects;

  @override
  void initState() {
    super.initState();
    _predefinedSubjects = widget.predefinedSubjects;
    _selectedSubjects = widget.selectedSubjects;
  }

  void _addNewSubject(String subject) {
    if (subject.isNotEmpty && !_selectedSubjects.contains(subject)) {
      setState(() {
        _selectedSubjects.add(subject);
        _predefinedSubjects.add(subject);
      });
      widget.onSubjectsChanged(_selectedSubjects);
    }
  }

  void _showAddSubjectDialog(BuildContext context) {
    final TextEditingController _newSubjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Subject'),
          content: TextField(
            controller: _newSubjectController,
            decoration: InputDecoration(hintText: "Enter subject name"),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                _addNewSubject(_newSubjectController.text);
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
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Select Subject',
            border: OutlineInputBorder(),
          ),
          items: _predefinedSubjects.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList()
            ..add(
              DropdownMenuItem<String>(
                value: 'add_new',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8.0),
                    Text('Add New Subject'),
                  ],
                ),
              ),
            ),
          onChanged: (String? newValue) {
            if (newValue == 'add_new') {
              _showAddSubjectDialog(context);
            } else if (newValue != null &&
                !_selectedSubjects.contains(newValue)) {
              setState(() {
                _selectedSubjects.add(newValue);
              });
              widget.onSubjectsChanged(_selectedSubjects);
            }
          },
        ),
        const SizedBox(height: 16.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedSubjects.map((subject) {
            return Chip(
              label: Text(subject),
              deleteIcon: Icon(Icons.cancel),
              onDeleted: () {
                setState(() {
                  _selectedSubjects.remove(subject);
                });
                widget.onSubjectsChanged(_selectedSubjects);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
