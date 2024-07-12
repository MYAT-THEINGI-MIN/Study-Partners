import 'package:flutter/material.dart';
import 'package:sp_test/Service/groupService.dart';

class TrendingSubjectsPage extends StatelessWidget {
  const TrendingSubjectsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Subjects'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: groupService.getTrendingSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No trending subjects found'));
          }

          // Sort subjects by count in descending order
          var sortedSubjects = snapshot.data!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView.builder(
            itemCount: sortedSubjects.length,
            itemBuilder: (context, index) {
              var subject = sortedSubjects[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((index + 1).toString()), // Leaderboard position
                  ),
                  title: Text(subject.key),
                  trailing: Text(
                    subject.value.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
