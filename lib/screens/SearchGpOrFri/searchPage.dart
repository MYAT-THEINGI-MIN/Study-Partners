import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/Service/RefreshIndicator.dart';
import 'package:sp_test/screens/SearchGpOrFri/EditInterests.dart';
import 'package:sp_test/screens/SearchGpOrFri/SearchFriPg.dart';
import 'package:sp_test/screens/SearchGpOrFri/TrendingSubjects.dart';
import 'package:sp_test/screens/SearchGpOrFri/searchGpPg.dart';
import 'package:sp_test/screens/SearchGpOrFri/GroupCards.dart'; // Import GroupCard

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPartnerPgState createState() => _SearchPartnerPgState();
}

class _SearchPartnerPgState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = []; // This will hold the search results
  RefreshController _refreshController = RefreshController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicatorWidget(
          // Wrap your content in RefreshIndicatorWidget
          controller: _refreshController,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search group button
                Container(
                  width: double.infinity,
                  height: 150,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Search New Groups Or Search New Friends Here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            child: const Text('Search Groups'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchGroupsPage(),
                                ),
                              );
                            },
                          ),
                          ElevatedButton(
                            child: const Text('Search Friends'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchFriPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Trending Subject Page
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrendingSubjectsPage(),
                        ),
                      );
                    },
                    child: Text('View Trending Subjects>'),
                  ),
                ),
                const SizedBox(height: 5),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(child: Text('User data not found'));
                    }

                    Map<String, dynamic> userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    String? subjects = userData['interests'];

                    if (subjects == null || subjects.isEmpty) {
                      return Center(child: Text('No subjects found'));
                    }

                    List<String> subjectList = subjects
                        .split(',')
                        .map((subject) => subject.trim().toLowerCase())
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Interests:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditInterestsPage(),
                                  ),
                                ).then((_) {
                                  // Refresh data when returning from EditInterestsPage
                                  _refreshData();
                                });
                              },
                              child: Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: subjectList.map((subject) {
                            return Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Groups Matching Your Interests:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('groups')
                              .where('privacy',
                                  isEqualTo: 'Public') // Only public groups
                              .get(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (snapshot.data == null ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(child: Text('No groups found'));
                            }

                            List<DocumentSnapshot> filteredGroups = snapshot
                                .data!.docs
                                .where((DocumentSnapshot doc) {
                              Map<String, dynamic> groupData =
                                  doc.data() as Map<String, dynamic>;
                              String groupSubject = groupData['subject']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              return subjectList.any(
                                  (subject) => groupSubject.contains(subject));
                            }).toList();

                            if (filteredGroups.isEmpty) {
                              return Center(child: Text('No groups found'));
                            }

                            return Column(
                              children: filteredGroups
                                  .map((DocumentSnapshot document) {
                                Map<String, dynamic> groupData =
                                    document.data() as Map<String, dynamic>;
                                return GroupCard(
                                  profileUrl: groupData['profileUrl'],
                                  groupName: groupData['groupName'],
                                  subject: groupData['subject'],
                                  groupId: document.id, // Pass groupId here
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      // Implement your refresh logic here, if any
    });
  }
}
