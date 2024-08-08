import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

class EditInterestsPage extends StatefulWidget {
  @override
  _EditInterestsPageState createState() => _EditInterestsPageState();
}

class _EditInterestsPageState extends State<EditInterestsPage> {
  final TextEditingController _interestController = TextEditingController();
  List<String> _interests = [];
  final List<String> _predefinedSubjects = [
    'Html',
    'Css',
    'Java',
    'Flutter',
    'AI',
    'Art',
    'Graphic Design',
    'UiUx',
    'English',
    'Japanese',
    'Korean',
    'Chinese',
  ];
  List<String> _selectedSubjects = [];

  @override
  void initState() {
    super.initState();
    _fetchInterests();
  }

  void _fetchInterests() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      String interests = userDoc.data()!['interests'] ?? '';
      setState(() {
        _interests = interests
            .split(',')
            .map((interest) => interest.trim().toLowerCase())
            .toList();
        _selectedSubjects = List.from(_interests);
      });
    }
  }

  void _updateInterests(List<String> interests) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'interests': interests.join(', '),
    });
  }

  void _showAddSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newSubject = '';
        return AlertDialog(
          title: Text('Add New Subject'),
          content: TextField(
            onChanged: (value) {
              newSubject = value.trim();
            },
            decoration: InputDecoration(labelText: 'Subject Name'),
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
                if (newSubject.isNotEmpty &&
                    !_predefinedSubjects.contains(newSubject)) {
                  setState(() {
                    _predefinedSubjects.add(newSubject);
                    _selectedSubjects.add(newSubject);
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveInterests() {
    setState(() {
      _interests = List.from(_selectedSubjects);
      _updateInterests(_interests);
    });
    TopSnackBarWiidget(context, 'Interests updated successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Interests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedSubjects.map((subject) {
                return Chip(
                  label: Text(subject,
                      style: Theme.of(context).textTheme.bodySmall),
                  onDeleted: () {
                    setState(() {
                      _selectedSubjects.remove(subject);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Subject',
                border: OutlineInputBorder(),
              ),
              items: _predefinedSubjects.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: Theme.of(context).textTheme.bodySmall),
                );
              }).toList()
                ..add(
                  DropdownMenuItem<String>(
                    value: 'add_new',
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8.0),
                        Text('Add New Subject',
                            style: Theme.of(context).textTheme.bodySmall),
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
                }
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveInterests,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interestController.dispose();
    super.dispose();
  }
}
