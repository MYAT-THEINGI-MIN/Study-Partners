import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _codeController = TextEditingController();
  String _verificationMessage = '';
  bool _isVerified = false;

  Future<void> _verifyCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final code = _codeController.text;
    final doc = await FirebaseFirestore.instance
        .collection('verification_codes')
        .doc(user.uid)
        .get();
    if (doc.exists && doc['code'] == code) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': widget.email,
        // other user details here
      }, SetOptions(merge: true));
      setState(() {
        _isVerified = true;
        _verificationMessage = 'Email verified successfully!';
      });
    } else {
      setState(() {
        _verificationMessage = 'Invalid code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Email Verification')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  'A verification code has been sent to ${widget.email}. Please enter the code below.'),
              const SizedBox(height: 16.0),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Verification Code'),
                keyboardType: TextInputType.number,
                maxLength: 6,
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
                onPressed: _verifyCode,
                child: const Text('Verify Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
