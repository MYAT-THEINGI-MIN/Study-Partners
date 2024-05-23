import 'package:flutter/material.dart';

class AboutMePg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Me'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'This App is developed by GiGi with Flutter and also designed by GiGi',
            style: TextStyle(fontSize: 16.0),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
