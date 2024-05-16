import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/controllers/register/registerBloc.dart';
import 'package:sp_test/controllers/register/registerEvent.dart';
import 'package:sp_test/controllers/register/registerState.dart';
import 'package:sp_test/widgets/textfield.dart';

class RegisterPg extends StatefulWidget {
  @override
  _RegisterPgState createState() => _RegisterPgState();
}

class _RegisterPgState extends State<RegisterPg> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
                                  context.read<RegisterBloc>().add(
                                        RegisterButtonPressed(
                                          email: email,
                                          password: password,
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

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  EmailVerificationScreen({required this.email});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isVerified = false;
  String _verificationMessage = '';

  void _verifyEmail() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        setState(() {
          _isVerified = true;
          _verificationMessage = 'Email verified successfully!';
        });
      } else {
        setState(() {
          _verificationMessage =
              'Email not verified yet. Please check your inbox.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'A verification link has been sent to ${widget.email}. Please verify your email.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 16.0),
              if (_verificationMessage.isNotEmpty)
                Text(
                  _verificationMessage,
                  style:
                      TextStyle(color: _isVerified ? Colors.green : Colors.red),
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _verifyEmail,
                child: Text('I have verified my email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
