import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberActivityPage extends StatefulWidget {
  final String groupId;

  MemberActivityPage({required this.groupId});

  @override
  _MemberActivitySummaryPageState createState() =>
      _MemberActivitySummaryPageState();
}

class _MemberActivitySummaryPageState extends State<MemberActivityPage> {
  late Future<List<MemberActivity>> _memberActivityFuture;
  late Future<int> _highestPointsFuture;

  @override
  void initState() {
    super.initState();
    _highestPointsFuture = _fetchHighestPoints(widget.groupId);
    _memberActivityFuture = _fetchMemberActivity(widget.groupId);
  }

  Future<int> _fetchHighestPoints(String groupId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot leaderboardSnapshot = await firestore
        .collection('groups')
        .doc(groupId)
        .collection('LeaderBoard')
        .get();

    int highestPoints = 0;

    for (var doc in leaderboardSnapshot.docs) {
      int points = doc['points'] ?? 0;
      if (points > highestPoints) {
        highestPoints = points;
      }
    }

    return highestPoints;
  }

  Future<List<MemberActivity>> _fetchMemberActivity(String groupId) async {
    Map<String, MemberActivityData> memberActivityMap = {};
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch Plans
    QuerySnapshot planSnapshot = await firestore
        .collection('groups')
        .doc(groupId)
        .collection('plans')
        .get();
    for (var doc in planSnapshot.docs) {
      String uid = doc['uid'];
      memberActivityMap
          .putIfAbsent(uid, () => MemberActivityData())
          .createdPlans++;

      if (doc['tasks'] is Map<String, dynamic>) {
        Map<String, dynamic> tasks = doc['tasks'] as Map<String, dynamic>;
        tasks.forEach((task, data) {
          if (data['completed'] is List) {
            List<dynamic> completed = data['completed'];
            for (var userId in completed) {
              memberActivityMap
                  .putIfAbsent(userId, () => MemberActivityData())
                  .completedPlans++;
            }
          }
        });
      }
    }

    // Fetch Flashcards
    QuerySnapshot flashcardSnapshot = await firestore
        .collection('groups')
        .doc(groupId)
        .collection('Flashcards')
        .get();
    for (var doc in flashcardSnapshot.docs) {
      String uid = doc['creatorUid'];
      memberActivityMap
          .putIfAbsent(uid, () => MemberActivityData())
          .createdFlashcards++;
    }

    // Fetch Notes
    QuerySnapshot notesSnapshot = await firestore
        .collection('groups')
        .doc(groupId)
        .collection('notes')
        .get();
    for (var doc in notesSnapshot.docs) {
      String uid = doc['uid'];
      memberActivityMap
          .putIfAbsent(uid, () => MemberActivityData())
          .createdNotes++;
    }

    // Fetch Quizzes
    QuerySnapshot quizSnapshot = await firestore
        .collection('groups')
        .doc(groupId)
        .collection('Quiz')
        .get();
    for (var doc in quizSnapshot.docs) {
      String creatorUid = doc['creatorUid'];
      memberActivityMap
          .putIfAbsent(creatorUid, () => MemberActivityData())
          .createdQuizzes++;

      if (doc['marks'] is Map<String, dynamic>) {
        Map<String, dynamic> marks = doc['marks'] as Map<String, dynamic>;
        marks.forEach((uid, score) {
          memberActivityMap
              .putIfAbsent(uid, () => MemberActivityData())
              .answeredQuizzes++;
        });
      }
    }

    // Fetch user data (name, profile image, and points)
    List<MemberActivity> memberActivities = [];
    QuerySnapshot leaderboardSnapshot = await firestore
        .collection('groups')
        .doc(groupId)
        .collection('LeaderBoard')
        .get();

    for (var doc in leaderboardSnapshot.docs) {
      String uid = doc.id;
      int points = doc['points'] ?? 0;
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(uid).get();
      String userName = userDoc['username'];
      String profileImageUrl = userDoc['profileImageUrl'];
      MemberActivityData activityData =
          memberActivityMap[uid] ?? MemberActivityData();
      memberActivities.add(
          MemberActivity(uid, userName, profileImageUrl, activityData, points));
    }

    return memberActivities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Member Activity Summary"),
      ),
      body: FutureBuilder<List<MemberActivity>>(
        future: _memberActivityFuture,
        builder: (context, memberActivitySnapshot) {
          if (memberActivitySnapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (memberActivitySnapshot.hasError) {
            return Center(
                child: Text("Error: ${memberActivitySnapshot.error}"));
          } else if (!memberActivitySnapshot.hasData ||
              memberActivitySnapshot.data!.isEmpty) {
            return Center(child: Text("No activity data available."));
          }

          return FutureBuilder<int>(
            future: _highestPointsFuture,
            builder: (context, highestPointsSnapshot) {
              if (highestPointsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (highestPointsSnapshot.hasError) {
                return Center(
                    child: Text("Error: ${highestPointsSnapshot.error}"));
              } else if (!highestPointsSnapshot.hasData ||
                  highestPointsSnapshot.data == 0) {
                return Center(child: Text("No leaderboard data available."));
              }

              int highestPoints = highestPointsSnapshot.data!;
              int threshold = (highestPoints * 0.25).toInt();

              List<MemberActivity> memberActivities =
                  memberActivitySnapshot.data!;
              List<MemberActivity> belowThreshold = memberActivities
                  .where((member) => member.points < threshold)
                  .toList();
              List<MemberActivity> aboveThreshold = memberActivities
                  .where((member) => member.points >= threshold)
                  .toList();

              return ListView(
                children: [
                  if (belowThreshold.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "These members should study hard",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.red),
                      ),
                    ),
                  ...belowThreshold.map((member) => Card(
                        color: Colors.red[100],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(member.profileImageUrl),
                          ),
                          title: Text(member.userName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Plans Created: ${member.activityData.createdPlans}"),
                              Text(
                                  "Plans Completed: ${member.activityData.completedPlans}"),
                              Text(
                                  "Flashcards Created: ${member.activityData.createdFlashcards}"),
                              Text(
                                  "Notes Created: ${member.activityData.createdNotes}"),
                              Text(
                                  "Quizzes Created: ${member.activityData.createdQuizzes}"),
                              Text(
                                  "Quizzes Answered: ${member.activityData.answeredQuizzes}"),
                            ],
                          ),
                        ),
                      )),
                  if (aboveThreshold.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Members with good performance",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ...aboveThreshold.map((member) => Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(member.profileImageUrl),
                          ),
                          title: Text(member.userName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Plans Created: ${member.activityData.createdPlans}"),
                              Text(
                                  "Plans Completed: ${member.activityData.completedPlans}"),
                              Text(
                                  "Flashcards Created: ${member.activityData.createdFlashcards}"),
                              Text(
                                  "Notes Created: ${member.activityData.createdNotes}"),
                              Text(
                                  "Quizzes Created: ${member.activityData.createdQuizzes}"),
                              Text(
                                  "Quizzes Answered: ${member.activityData.answeredQuizzes}"),
                            ],
                          ),
                        ),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class MemberActivity {
  final String uid;
  final String userName;
  final String profileImageUrl;
  final MemberActivityData activityData;
  final int points; // Leaderboard points

  MemberActivity(this.uid, this.userName, this.profileImageUrl,
      this.activityData, this.points);
}

class MemberActivityData {
  int createdPlans = 0;
  int completedPlans = 0;
  int createdFlashcards = 0;
  int createdNotes = 0;
  int createdQuizzes = 0;
  int answeredQuizzes = 0;
}
