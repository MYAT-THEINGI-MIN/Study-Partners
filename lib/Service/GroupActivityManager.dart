import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GroupActivityManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to check and update study points based on inactivity for all groups
  Future<void> checkAndUpdateGroupActivity() async {
    try {
      // Fetch all groups from Firestore
      QuerySnapshot groupsSnapshot =
          await _firestore.collection('groups').get();

      for (QueryDocumentSnapshot groupDoc in groupsSnapshot.docs) {
        // Extract fields from the group document
        DateTime lastActivityTimestamp =
            (groupDoc['lastActivityTimestamp'] as Timestamp).toDate();
        int studyHardPoints = groupDoc['StudyHardPoint'];

        // Calculate the time difference
        DateTime now = DateTime.now();
        Duration difference = now.difference(lastActivityTimestamp);

        // Define the penalty criteria, e.g., 24 hours of inactivity
        if (difference.inHours >= 24) {
          int pointsToDeduct = calculatePointsToDeduct(difference.inHours);

          // Deduct points
          int updatedStudyPoints = studyHardPoints - pointsToDeduct;
          if (updatedStudyPoints < 0)
            updatedStudyPoints = 0; // Ensure points don't go negative

          // Update the Firestore document
          await _firestore.collection('groups').doc(groupDoc.id).update({
            'StudyHardPoint': updatedStudyPoints,
            'lastActivityTimestamp':
                now, // Update the timestamp after applying penalty
          });
        }
      }
    } catch (e) {
      print('Error updating group study points: $e');
    }
  }

  // Method to calculate points to deduct based on the inactivity duration
  int calculatePointsToDeduct(int hoursOfInactivity) {
    // Example logic: deduct 10 points per day of inactivity
    int daysInactive = (hoursOfInactivity / 24).floor();
    return daysInactive * 10;
  }
}
