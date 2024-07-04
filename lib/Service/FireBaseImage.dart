import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseImage extends StatelessWidget {
  final String
      imagePath; // Path in Firebase Storage (e.g., 'appImages/lock-unscreen.gif')

  FirebaseImage({required this.imagePath});

  Future<String> _getDownloadUrl() async {
    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef.child(imagePath);
    final downloadUrl = await imageRef.getDownloadURL();
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getDownloadUrl(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Image.network(snapshot.data!);
        }
      },
    );
  }
}
