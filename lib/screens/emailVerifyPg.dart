import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
                child: const Text('I have verified my email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
