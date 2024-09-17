import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupLinksPage extends StatefulWidget {
  final String groupId;

  GroupLinksPage({required this.groupId});

  @override
  _GroupLinksPageState createState() => _GroupLinksPageState();
}

class _GroupLinksPageState extends State<GroupLinksPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to fetch group links for a specific groupId
  Stream<QuerySnapshot> _getGroupLinks() {
    return _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('grouplinks')
        .snapshots();
  }

  // Future to fetch user profile based on UID
  Future<Map<String, dynamic>> _getUserProfile(String uid) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(uid).get();
    return userSnapshot.data() as Map<String, dynamic>;
  }

  // Function to open the URL in the browser
  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Links'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getGroupLinks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Nobody share links in this group.'),
            );
          }

          var links = snapshot.data!.docs;

          return ListView.builder(
            itemCount: links.length,
            itemBuilder: (context, index) {
              var linkData = links[index];
              String linkUrl = linkData['link'] ?? 'No link';
              String addedBy = linkData['addedBy'] ?? 'Unknown user';
              Timestamp timestamp = linkData['timestamp'] ?? Timestamp.now();

              // Display the user profile information
              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserProfile(addedBy),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      title: Text('Link: $linkUrl'),
                      subtitle: Text('User info not found.'),
                    );
                  }

                  var userProfile = userSnapshot.data!;
                  String username = userProfile['username'] ?? 'Unknown';
                  String profileImageUrl = userProfile['profileImageUrl'] ?? '';
                  String formattedDate = DateTime.fromMillisecondsSinceEpoch(
                    timestamp.millisecondsSinceEpoch,
                  ).toString();

                  return Card(
                    child: ListTile(
                      leading: profileImageUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(profileImageUrl),
                            )
                          : CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: GestureDetector(
                        onTap: () {
                          // Open the URL when tapped
                          _launchUrl(linkUrl);
                        },
                        child: Text(
                          'Link: $linkUrl',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Added by: $username'),
                          Text('Date: $formattedDate'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
