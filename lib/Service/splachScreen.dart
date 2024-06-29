import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final int duration;
  final Widget nextPage;

  SplashScreen({required this.duration, required this.nextPage});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            Text(
              'for more effective study hours',
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


// //image//
// Image.network(
//               "https://i.pinimg.com/originals/ba/1b/ba/ba1bba349c9b8772806a8fd8de2a86d6.gif",
//               loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
//                 if (loadingProgress == null) {
//                   return child;
//                 }
//                 return CircularProgressIndicator(
//                   value: loadingProgress.expectedTotalBytes != null
//                       ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                       : null,
//                 );
//               },
//               errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
//                 return Text('Failed to load image');
//               },
//             ),