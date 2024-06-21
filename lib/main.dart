import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/routes/router.dart';
import 'package:sp_test/screens/SplashScreen.dart';
import 'package:sp_test/screens/homePg.dart';
import 'package:sp_test/screens/loginPg.dart';
import 'screens/homePg.dart';
import 'screens/loginPg.dart';

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
      home: SplashScreen(),
      onGenerateRoute: router,
    );
  }
}

//myattheingimin3532@gmail.com
//Myat@2019

//wwp68706@doolk.com
//Wwp68706@