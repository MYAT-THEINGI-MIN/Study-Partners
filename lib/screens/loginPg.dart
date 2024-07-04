import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/controllers/login/loginBloc.dart';
import 'package:sp_test/controllers/login/loginEvent.dart';
import 'package:sp_test/controllers/login/loginState.dart';
import 'package:sp_test/widgets/textfield.dart';
import 'homePg.dart';
import 'registerPg.dart';

class LoginPg extends StatefulWidget {
  @override
  _LoginPgState createState() => _LoginPgState();
}

class _LoginPgState extends State<LoginPg> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocProvider(
        create: (context) => LoginBloc(auth: FirebaseAuth.instance),
        child: Builder(
          builder: (context) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/lock.gif'),
                  SizedBox(height: 10.0),
                  BlocConsumer<LoginBloc, LoginState>(
                    listener: (context, state) {
                      if (state is LoginFailure) {
                        showTopSnackBar(
                            context, 'Incorrect! Please Check Again');
                      } else if (state is LoginSuccess) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomePg()),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is LoginLoading) {
                        return const CircularProgressIndicator();
                      }

                      return Column(
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            obscureText: false,
                            onSuffixIconPressed: () {},
                            showSuffixIcon: false,
                          ),
                          const SizedBox(height: 5.0),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            obscureText: _obscureText,
                            onSuffixIconPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Container(
                            padding: EdgeInsets.only(left: 5, right: 5),
                            child: ElevatedButton(
                              onPressed: () {
                                final email = _emailController.text;
                                final password = _passwordController.text;
                                print(
                                    'Login button pressed with email: $email, password: $password'); // Debug print

                                context.read<LoginBloc>().add(
                                      LoginButtonPressed(
                                        email: email,
                                        password: password,
                                      ),
                                    );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple
                                    .shade100, // Background color of the button
                                padding: EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 20.0,
                                ), // Adjust padding as needed
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Optional: Button border radius
                                ),
                              ),
                              child: Container(
                                width: double.infinity, // Full width button
                                alignment: Alignment.center,
                                child: const Text('Login'),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _resetPassword(_emailController.text);
                            },
                            child: const Text('Forgot Password?'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPg(),
                                ),
                              );
                            },
                            child: const Text('Register'),
                          ),
                        ],
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

  // "Forgot Password" button press
  void _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showTopSnackBar(
          context, 'Password reset was sent. Please check your Email.');
    } catch (error) {
      showTopSnackBar(context, 'Please fill Email first.');
    }
  }
}

void showTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50.0,
      left: MediaQuery.of(context).size.width * 0.1,
      right: MediaQuery.of(context).size.width * 0.1,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Color.fromARGB(221, 43, 43, 43),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            message,
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  overlay?.insert(overlayEntry);
  Future.delayed(Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
