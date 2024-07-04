import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  final int duration;
  final Widget nextPage;

  SplashScreen({required this.duration, required this.nextPage});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late String randomText;

  @override
  void initState() {
    super.initState();
    print('SplashScreen initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(Duration(seconds: widget.duration), () {
        print("Timer finished, navigating to next page.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextPage),
        );
      });
    });

    List<String> texts = [
      'for more effective study hours',
      'learn together, grow together',
      'partnered study, better results',
      'team up for success',
      'study smart, study with friends'
    ];

    Random random = Random();
    randomText = texts[random.nextInt(texts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 247, 235, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            Text(
              randomText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'Study With Partners',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}
