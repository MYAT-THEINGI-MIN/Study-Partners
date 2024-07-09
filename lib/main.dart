import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sp_test/Service/splachScreen.dart';
import 'package:sp_test/Service/theme.dart';
import 'package:sp_test/Service/themeProvider.dart';
import 'package:sp_test/routes/router.dart';
import 'package:sp_test/screens/homePg.dart';
import 'package:sp_test/screens/loginOrRegiser.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  MyApp() {
    final initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final initializationSettingsIOS = IOSInitializationSettings();
    final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(String message) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iOSPlatformChannelSpecifics = IOSNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Theme Changed',
      message,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Add listener to the themeProvider
          themeProvider.addListener(() {
            _scheduleNotification(
                'Theme changed to ${themeProvider.isDarkMode ? "Dark" : "Light"} mode');
          });
          return MaterialApp(
            title: 'Study Partners',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _handleInitialScreen(),
            onGenerateRoute: router,
          );
        },
      ),
    );
  }

  Widget _handleInitialScreen() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(
            duration: 3,
            nextPage: HomePg(),
          ); // Show splash for 3 seconds while waiting for connection
        } else {
          if (snapshot.hasData) {
            // User is logged in
            return SplashScreen(
                duration: 3,
                nextPage: HomePg()); // Show splash for 3 seconds if logged in
          } else {
            // User is not logged in
            return SplashScreen(
                duration: 3,
                nextPage:
                    LoginOrRegister()); // Show splash for 3 seconds if not logged in
          }
        }
      },
    );
  }
}


//using theme provider//splach screen update//

//myattheingimin3532@gmail.com
//Myat@2019

//wwp68706@doolk.com
//Wwp68706@

//yairzawhtun007@gmail.com
//yairzawhtun12#


