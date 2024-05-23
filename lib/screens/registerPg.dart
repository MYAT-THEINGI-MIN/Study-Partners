import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/controllers/register/registerBloc.dart';
import 'package:sp_test/controllers/register/registerEvent.dart';
import 'package:sp_test/controllers/register/registerState.dart';
import 'package:sp_test/screens/emailVerifyPg.dart';
import 'package:sp_test/widgets/textfield.dart';

class RegisterPg extends StatefulWidget {
  @override
  _RegisterPgState createState() => _RegisterPgState();
}

class _RegisterPgState extends State<RegisterPg> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController =
      TextEditingController(); // Add this line
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureText = true; // State variable for password visibility

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
              // Wrap the content in SingleChildScrollView
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://i.pinimg.com/564x/84/17/9e/84179edf09d79962b0c68c1642dbc1b8.jpg', // image URL
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 24.0),
                  BlocConsumer<RegisterBloc, RegisterState>(
                    listener: (context, state) {
                      if (state is RegisterFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to register: ${state.error}'),
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (state is RegisterSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Registration successful. Please verify your email.'),
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EmailVerificationScreen(
                                  email: _emailController.text)),
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
                              // Use CustomTextField for username
                              controller: _usernameController, // Add this line
                              labelText: 'Username', // Add this line
                              showSuffixIcon: false, // Add this line
                              validator: (value) {
                                // Add this line
                                if (value == null || value.isEmpty) {
                                  // Add this line
                                  return 'Please enter your username'; // Add this line
                                }
                                return null; // Add this line
                              },
                              onSuffixIconPressed: () {}, // Add this line
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextField(
                              // Use CustomTextField for email
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
                              // Use CustomTextField for password
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
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final email = _emailController.text;
                                  final password = _passwordController.text;
                                  final username =
                                      _usernameController.text; // Add this line
                                  context.read<RegisterBloc>().add(
                                        RegisterButtonPressed(
                                          email: email,
                                          password: password,
                                          username: username, // Add this line
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
