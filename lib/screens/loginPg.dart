import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sp_test/controllers/login/loginBloc.dart';
import 'package:sp_test/controllers/login/loginEvent.dart';
import 'package:sp_test/controllers/login/loginState.dart';
import 'package:sp_test/screens/GpChat/addPartner.dart';
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

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://i.pinimg.com/564x/84/17/9e/84179edf09d79962b0c68c1642dbc1b8.jpg', // image URL
                    height: 100,
                    width: 100,
                  ),
                  SizedBox(height: 24.0),
                  BlocConsumer<LoginBloc, LoginState>(
                    listener: (context, state) {
                      if (state is LoginFailure) {
                        showTopSnackBar(
                            context, 'Failed to login: ${state.error}');
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
                          ),
                          const SizedBox(height: 16.0),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
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
                                backgroundColor: Colors.deepPurple.shade100,
                              ),
                              child: const Text('Login'),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _signInWithGoogle(context);
                              },
                              icon: Icon(Icons.login),
                              label: Text('Sign in with Google'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Password reset email was sent.Check your mail please.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      showTopSnackBar(context, 'Enter the email first');
    }
  }

  // Google Sign-In method
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePg()),
          );
        }
      }
    } catch (error) {
      print('Error signing in with Google: $error');
      showTopSnackBar(context, 'Failed to sign in with Google: $error');
    }
  }
}
