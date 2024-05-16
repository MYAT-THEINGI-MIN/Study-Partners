import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/routes/router.dart';
import 'package:sp_test/screens/homePg.dart';
import 'package:sp_test/screens/loginPg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Firebase Demo',
      home: BlockAuthFlow(),
      onGenerateRoute: router,
    );
  }
}

class BlockAuthFlow extends StatelessWidget {
  const BlockAuthFlow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading indicator while waiting for authentication state
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle error state
          return Text('Error: ${snapshot.error}');
        } else {
          // If user is authenticated, navigate to home page
          if (snapshot.hasData && snapshot.data != null) {
            return homePg();
          }
          // If user is not authenticated, navigate to login page
          return LoginPg();
        }
      },
    );
  }
}
