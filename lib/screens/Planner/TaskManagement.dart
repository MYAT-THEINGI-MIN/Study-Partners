import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskManagement {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void deleteTask(String id) {
    User? currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .doc(id)
          .delete();
    }
  }

  void markTaskAsDone(String id) {
    User? currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .doc(id)
          .get()
          .then((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final originalColor =
            data['color'] ?? Colors.white.value; // Retrieve current color
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks')
            .doc(id)
            .update({
          'color': const Color.fromARGB(255, 222, 222, 222)
              .value, // Set color as done
          'isDone': true,
          'originalColor': originalColor, // Store original color for later use
        });
      });
    }
  }

  void markTaskAsUndone(String id) {
    User? currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks')
          .doc(id)
          .get()
          .then((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final originalColor = data['originalColor'] ??
            Colors.white.value; // Retrieve stored original color
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks')
            .doc(id)
            .update({
          'color': originalColor, // Revert to original color
          'isDone': false,
        });
      });
    }
  }
}
