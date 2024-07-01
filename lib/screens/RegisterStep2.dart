import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/controllers/register/registerBloc.dart';
import 'package:sp_test/controllers/register/registerEvent.dart';
import 'package:sp_test/controllers/register/registerState.dart';
import 'package:sp_test/screens/emailVerifyPg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:sp_test/widgets/topSnackBar.dart';

class UploadImageScreen extends StatefulWidget {
  final String email;
  final String password;
  final String username;
  final String subjects;

  UploadImageScreen({
    required this.email,
    required this.password,
    required this.username,
    required this.subjects,
  });

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
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
                            builder: (context) =>
                                EmailVerificationScreen(email: widget.email),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is RegisterLoading) {
                        return const CircularProgressIndicator();
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_profileImage != null) {
                              context.read<RegisterBloc>().add(
                                    RegisterButtonPressed(
                                      email: widget.email,
                                      password: widget.password,
                                      username: widget.username,
                                      subjects: widget.subjects,
                                      profileImage: _profileImage,
                                    ),
                                  );
                            } else {
                              showTopSnackBar(
                                  context, 'Please upload a profile image.');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade100,
                          ),
                          child: Text('Register',
                              style: Theme.of(context).textTheme.bodyMedium),
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
