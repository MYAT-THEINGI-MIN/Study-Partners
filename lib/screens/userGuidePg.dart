import 'package:flutter/material.dart';

class UserGuidePg extends StatelessWidget {
  const UserGuidePg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Text(
          'User Guide Content Goes Here',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
