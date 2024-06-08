import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/controllers/register/registerBloc.dart';
import 'package:sp_test/controllers/register/registerEvent.dart';
import 'package:sp_test/controllers/register/registerState.dart';
import 'package:sp_test/screens/emailVerifyPg.dart';
import 'package:sp_test/widgets/textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  final TextEditingController _subjectsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  File? _profileImage;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
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
                  _profileImage != null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: FileImage(_profileImage!),
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          child: IconButton(
                            icon: Icon(Icons.camera_alt),
                            onPressed: _pickImage,
                          ),
                        ),
                  const SizedBox(height: 24.0),
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
                            builder: (context) => EmailVerificationScreen(
                                email: _emailController.text),
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
                            CustomTextField(
                              controller: _subjectsController,
                              labelText: 'Subjects',
                              showSuffixIcon: false,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your subjects';
                                }
                                return null;
                              },
                              onSuffixIconPressed: () {},
                            ),
                            const SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final email = _emailController.text;
                                  final password = _passwordController.text;
                                  final username = _usernameController.text;
                                  final subjects = _subjectsController.text;
                                  context.read<RegisterBloc>().add(
                                        RegisterButtonPressed(
                                          email: email,
                                          password: password,
                                          username: username,
                                          subjects: subjects,
                                          profileImage: _profileImage,
                                        ),
                                      );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade100,
                              ),
                              child: Text('Register'),
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
