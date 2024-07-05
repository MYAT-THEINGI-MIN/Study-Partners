import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatelessWidget {
  final String groupId;

  LeaderboardPage({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: FutureBuilder<List<Member>>(
        future: fetchLeaderboard(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            List<Member> members = snapshot.data!;
            return ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                Member member = members[index];
                return ListTile(
                  title: Text(member.name),
                  trailing: Text(member.points.toString()),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Member>> fetchLeaderboard(String groupId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .orderBy('points', descending: true)
          .get();

      List<Member> members = querySnapshot.docs.map((doc) {
        return Member.fromDocument(doc);
      }).toList();

      return members;
    } catch (e) {
      throw e;
    }
  }
}

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
