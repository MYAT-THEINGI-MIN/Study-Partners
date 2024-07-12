import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getTrendingSubjects() async {
    QuerySnapshot querySnapshot = await _firestore.collection('groups').get();
    Map<String, int> subjectCounts = {};

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String subject = (data['subject'] as String?)?.toLowerCase() ?? '';

      if (subject.isNotEmpty) {
        if (subjectCounts.containsKey(subject)) {
          subjectCounts[subject] = subjectCounts[subject]! + 1;
        } else {
          subjectCounts[subject] = 1;
        }
      }
    }

    return subjectCounts;
  }
}
