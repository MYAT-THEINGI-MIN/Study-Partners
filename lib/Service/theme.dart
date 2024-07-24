import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.deepPurple,
    brightness: Brightness.light,
    primarySwatch: Colors.deepPurple,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: Color.fromARGB(
        255, 255, 255, 255), // Set background color to pure white
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 18, color: Colors.black87),
      bodyLarge: TextStyle(fontSize: 22, color: Colors.black),
      bodySmall: TextStyle(fontSize: 16, color: Colors.black),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.deepPurple,
    hintColor: Colors.deepPurpleAccent,
    scaffoldBackgroundColor:
        Color.fromARGB(255, 0, 0, 51), // Navy blue background
    cardColor: Colors.blueGrey[800],
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 0, 0, 51), // Navy blue app bar
      elevation: 0,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.deepPurple,
      textTheme: ButtonTextTheme.primary,
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 18, color: Colors.white70),
      bodyLarge: TextStyle(fontSize: 22, color: Colors.white),
      bodySmall: TextStyle(fontSize: 16, color: Colors.white70),
    ),
  );
}
