import 'package:cloud_firestore/cloud_firestore.dart';

class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new member to the group with initial points
  Future<void> addMemberToGroup(
      String groupId, String memberId, String memberName) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId)
        .set({
      'name': memberName,
      'points': 0,
    });
  }

  // Update points for a member
  Future<void> updateMemberPoints(
      String groupId, String memberId, int points) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId)
        .update({
      'points': FieldValue.increment(points),
    });
  }

  // Fetch and return the leaderboard for a group
  Future<List<Member>> fetchLeaderboard(String groupId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .orderBy('points', descending: true)
        .get();

    return snapshot.docs.map((doc) => Member.fromDocument(doc)).toList();
  }
}

// Member model class
class Member {
  final String id;
  final String name;
  final int points;

  Member({required this.id, required this.name, required this.points});

  factory Member.fromDocument(DocumentSnapshot doc) {
    return Member(
      id: doc.id,
      name: doc['name'],
      points: doc['points'],
    );
  }
}
