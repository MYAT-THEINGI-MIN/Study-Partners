import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/controllers/register/registerBloc.dart';
import 'package:sp_test/controllers/register/registerEvent.dart';
import 'package:sp_test/controllers/register/registerState.dart';
import 'package:sp_test/screens/RegisterStep2.dart';
import 'package:sp_test/widgets/textfield.dart';
import 'package:sp_test/widgets/topSnackBar.dart';

class RegisterPg extends StatefulWidget {
  @override
  _RegisterPgState createState() => _RegisterPgState();
}

class _RegisterPgState extends State<RegisterPg> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  final List<String> _predefinedSubjects = [
    'Java',
    'Html',
    'CSS',
    'Flutter',
    'Art',
    'Japanese',
    'Korean',
    'Chinese',
    'English'
  ];
  List<String> _selectedSubjects = [];

  void _addNewSubject(String subject) {
    if (subject.isNotEmpty && !_selectedSubjects.contains(subject)) {
      setState(() {
        _selectedSubjects.add(subject);
        _predefinedSubjects.add(subject);
      });
    }
  }

  void _showAddSubjectDialog(BuildContext context) {
    final TextEditingController _newSubjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Subject',
              style: Theme.of(context).textTheme.bodyMedium),
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
    return Scaffold(
      appBar: AppBar(),
      body: BlocProvider(
        create: (context) => RegisterBloc(auth: FirebaseAuth.instance),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BlocConsumer<RegisterBloc, RegisterState>(
                    listener: (context, state) {
                      if (state is RegisterFailure) {
                        showTopSnackBar(
                            context, 'Failed to register: ${state.error}');
                      } else if (state is RegisterSuccess) {
                        showTopSnackBar(context,
                            'Registration successful. Please verify your email.');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UploadImageScreen(
                              email: _emailController.text,
                              password: _passwordController.text,
                              username: _usernameController.text,
                              subjects: _selectedSubjects.join(', '),
                            ),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is RegisterLoading) {
                        return const CircularProgressIndicator();
                      }

                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _usernameController,
                              labelText: 'Username',
                              showSuffixIcon: false,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your username';
                                }
                                return null;
                              },
                              onSuffixIconPressed: () {},
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextField(
                              controller: _emailController,
                              labelText: 'Email',
                              showSuffixIcon: false,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                              onSuffixIconPressed: () {},
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              obscureText: _obscureText,
                              onSuffixIconPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              obscureText: _obscureText,
                              onSuffixIconPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                } else if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
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
                                  child: Text(value,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
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
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: _selectedSubjects.map((subject) {
                                return Chip(
                                  label: Text(subject,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedSubjects.remove(subject);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final email = _emailController.text;
                                    final password = _passwordController.text;
                                    final username = _usernameController.text;
                                    final subjects =
                                        _selectedSubjects.join(', ');
                                    context.read<RegisterBloc>().add(
                                          RegisterButtonPressed(
                                            email: email,
                                            password: password,
                                            username: username,
                                            subjects: subjects,
                                          ),
                                        );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade100,
                                ),
                                child: Text('Next',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
