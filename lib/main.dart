import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/routes/router.dart';
import 'package:sp_test/screens/SplashScreen.dart';
import 'package:sp_test/screens/homePg.dart';

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
      home:
          _handleInitialScreen(), // Determine initial screen based on authentication state
      onGenerateRoute: router,
    );
  }

  Widget _handleInitialScreen() {
    // Function to determine initial screen based on authentication state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for connection, show loading or splash screen
          return SplashScreen();
        } else {
          if (snapshot.hasData) {
            // User is logged in
            return HomePg();
          } else {
            // User is not logged in
            return SplashScreen(); // Or your login/signup screen
          }
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