import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  Future<void> saveTask({
    required String uid,
    required String title,
    required String note,
    required DateTime date,
    required String time,
    required String repeat,
    required String remind,
    required String color,
  }) async {
    try {
      String formattedDate =
          date.toIso8601String(); // Use ISO-8601 format for timestamp

      int colorValue = int.parse(
          color.replaceFirst('#', '0x')); // Convert hex string to integer

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(formattedDate) // Use formattedDate as document ID
          .set({
        'title': title,
        'note': note,
        'date': formattedDate, // Store date as ISO-8601 string
        'time': time,
        'repeat': repeat,
        'remind': remind,
        'color': colorValue, // Store color as integer
        // Add other fields as needed
      });

      print('Task saved successfully');
    } catch (e) {
      print('Error saving task: $e');
      // Handle errors as needed
    }
  }
}

//