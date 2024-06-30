import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTask({
    required String uid,
    required String title,
    required String note,
    required DateTime date,
    required String time,
    required String repeat,
    required String remind,
    required int color, // Change type to int
  }) async {
    await _firestore.collection('users').doc(uid).collection('tasks').add({
      'title': title,
      'note': note,
      'date': date.toIso8601String(),
      'time': time,
      'repeat': repeat,
      'remind': remind,
      'color': color, // Save as int
    });
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateTask({
    required String uid,
    required String taskId,
    required String title,
    required String note,
    required String date,
    required String time,
    required String repeat,
    required String remind,
    required int color,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .update({
      'title': title,
      'note': note,
      'date': date,
      'time': time,
      'repeat': repeat,
      'remind': remind,
      'color': color,
    });
  }
}
