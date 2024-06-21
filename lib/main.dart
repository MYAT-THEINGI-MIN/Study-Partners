import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/routes/router.dart';
import 'package:sp_test/screens/SplashScreen.dart';
import 'package:sp_test/screens/homePg.dart';
import 'package:sp_test/screens/loginPg.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/routes/router.dart';
import 'package:sp_test/screens/SplashScreen.dart';
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
    return MaterialApp(
      title: 'Firebase Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      onGenerateRoute: router,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(); // Show loading screen while checking auth state
        } else if (snapshot.hasData) {
          // User is logged in
          return HomePg(); // Navigate to home page if user is authenticated
        } else {
          // User is not logged in
          return SplashScreen(); // Navigate to login page if user is not authenticated
        }
      },
    );
  }
}



//myattheingimin3532@gmail.com
//Myat@2019

//wwp68706@doolk.com
//Wwp68706@

//yairzawhtun007@gmail.com
//yairzawhtun12#