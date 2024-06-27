import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotifyHelper {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotification() async {
    try {
      final AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings("appicon");

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: selectNotification,
      );
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future selectNotification(String? payload) async {
    try {
      if (payload != null) {
        print('notification payload: $payload');
      } else {
        print("Notification Done");
      }
      Get.to(() => Container(color: Colors.deepPurple));
    } catch (e) {
      print("Error in selectNotification: $e");
    }
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    try {
      Get.dialog(Text("welcome"));
    } catch (e) {
      print("Error in onDidReceiveLocalNotification: $e");
    }
  }

  Future<void> requestAndroidPermissions() async {
    try {
      PermissionStatus status = await Permission.notification.status;
      print('Initial notification permission status: $status');

      if (status.isDenied || status.isPermanentlyDenied) {
        PermissionStatus requestStatus =
            await Permission.notification.request();
        print('Notification permission request status: $requestStatus');
        if (requestStatus != PermissionStatus.granted) {
          print('Notification permission denied');
        } else {
          print('Notification permission granted');
        }
      }
    } catch (e) {
      print("Error requesting notification permissions: $e");
    }
  }
}
