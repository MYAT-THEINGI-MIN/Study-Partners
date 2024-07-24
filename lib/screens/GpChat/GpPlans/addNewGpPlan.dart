import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sp_test/widgets/textfield.dart';

class AddNewPlan extends StatefulWidget {
  final String groupId;

  AddNewPlan({required this.groupId});

  @override
  _AddNewPlanState createState() => _AddNewPlanState();
}

class _AddNewPlanState extends State<AddNewPlan> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDeadline;

  Future<void> _pickDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _addNewPlan() async {
    if (_formKey.currentState!.validate()) {
      String title = _titleController.text;
      String description = _descriptionController.text;
      DateTime deadline = _selectedDeadline!;
      String note = _noteController.text;
      String groupId = widget.groupId;
      String uid = FirebaseAuth.instance.currentUser!.uid;

      try {
        // Fetch current user's username
        DocumentSnapshot documentSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!documentSnapshot.exists) {
          throw Exception("User document does not exist");
        }

        String username = documentSnapshot['username'];

        // Create a task with the given title and deadline
        Map<String, dynamic> task = {
          'title': title,
          'deadline': DateFormat("yyyy-MM-ddTHH:mm:ss.sss").format(deadline),
          'completed': [], // Empty list for completed users
        };

        // Add new plan document to Firestore
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('plans')
            .add({
          'planName': title, // Save plan name
          'description': description, // Save description
          'tasks': [task], // Save task as part of tasks array
          'note': note, // Save note
          'username': username,
          'uid': uid, // Save uid outside of tasks array
        });

        Navigator.pop(context);
      } catch (e) {
        print('Error adding plan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add plan. Please try again.')),
        );
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Plan'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Title',
                  onSuffixIconPressed: () {},
                  showSuffixIcon: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  onSuffixIconPressed: () {},
                  showSuffixIcon: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                InkWell(
                  onTap: () => _pickDeadline(context),
                  child: IgnorePointer(
                    child: CustomTextField(
                      controller: _deadlineController,
                      labelText: 'Deadline',
                      onSuffixIconPressed: () {},
                      showSuffixIcon: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please pick a deadline';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                CustomTextField(
                  controller: _noteController,
                  labelText: 'Note',
                  onSuffixIconPressed: () {},
                  showSuffixIcon: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a note';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addNewPlan,
                        child: Text('Add Plan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
