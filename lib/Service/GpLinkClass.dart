import 'package:cloud_firestore/cloud_firestore.dart';

class GroupLink {
  final String groupId;
  final String link;
  final String addedBy;
  final Timestamp timestamp;

  GroupLink({
    required this.groupId,
    required this.link,
    required this.addedBy,
    required this.timestamp,
  });

  // Convert GroupLink object to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'link': link,
      'addedBy': addedBy,
      'timestamp': timestamp,
    };
  }

  // Factory constructor to create a GroupLink from Firestore data
  factory GroupLink.fromMap(Map<String, dynamic> map) {
    return GroupLink(
      groupId: map['groupId'] ?? '',
      link: map['link'] ?? '',
      addedBy: map['addedBy'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
