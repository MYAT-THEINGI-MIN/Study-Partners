import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sp_test/screens/GpChat/Study%20Timer/studyRecordCard.dart';

class AllStudyRecordsList extends StatelessWidget {
  final String groupId;

  AllStudyRecordsList({required this.groupId});

  Future<List<QueryDocumentSnapshot>> _fetchAllStudyRecords() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final startTimestamp = Timestamp.fromDate(startOfDay);
      final endTimestamp = Timestamp.fromDate(endOfDay);

      final recordsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('StudyRecord')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .orderBy('timestamp', descending: true)
          .get();

      return recordsSnapshot.docs;
    } catch (e) {
      print('Error fetching records: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchAllStudyRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // This is where the message is defined
          return const Center(child: Text('No one has studied yet today.'));
        }

        final records = snapshot.data!;

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index].data() as Map<String, dynamic>;
            final recordId = records[index].id;

            return StudyRecordCard(
              recordId: recordId,
              formattedDate: record['formattedDate'] ?? '',
              totalTime: record['totalTime'] ?? 0,
              totalBreaks: record['totalBreaks'] ?? 0,
              breakTime: record['breakTime'] ?? 0,
              groupId: groupId,
            );
          },
        );
      },
    );
  }
}
