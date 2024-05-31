import 'package:firebase_messaging/firebase_messaging.dart';

class MyMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Function to handle receiving messages while the app is in the foreground
  void handleMessage(Map<String, dynamic> message) {
    print("Received message: $message");
    // Handle the message here
  }

  // Function to handle receiving messages while the app is in the background or terminated
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print("Received background message: $message");
    // Handle the message here
  }

  // Function to get the device token
  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Function to initialize Firebase Cloud Messaging
  void initializeFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
      handleMessage(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle messages clicked from the notification
      print("Message clicked: $message");
    });

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }
}

// Example usage:
void main() {
  MyMessagingService messagingService = MyMessagingService();
  messagingService.initializeFCM();
}
