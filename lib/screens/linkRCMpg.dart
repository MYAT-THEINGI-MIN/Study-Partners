import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkRecommendationPage extends StatefulWidget {
  final String uid;

  const LinkRecommendationPage({Key? key, required this.uid}) : super(key: key);

  @override
  _LinkRecommendationPageState createState() => _LinkRecommendationPageState();
}

class _LinkRecommendationPageState extends State<LinkRecommendationPage> {
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchUserSubjects();
  }

  Future<void> _fetchUserSubjects() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    String subjectString = userDoc['subjects'];
    setState(() {
      subjects = subjectString.split(',').map((s) => s.trim()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Links Recommendations'),
      ),
      body: subjects.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                String subject = subjects[index];
                String courseLink = _getCourseLink(subject);
                String tutorialLink = _getTutorialLink(subject);
                String jobLink = _getJobLink(subject);

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject: $subject',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 8),
                          Text('Recommended Online Courses:'),
                          InkWell(
                            child: Text(
                              courseLink,
                              style: TextStyle(color: Colors.blue),
                            ),
                            onTap: () => _launchURL(courseLink),
                          ),
                          SizedBox(height: 8),
                          Text('YouTube Tutorials:'),
                          InkWell(
                            child: Text(
                              tutorialLink,
                              style: TextStyle(color: Colors.blue),
                            ),
                            onTap: () => _launchURL(tutorialLink),
                          ),
                          SizedBox(height: 8),
                          Text('Job Opportunities:'),
                          InkWell(
                            child: Text(
                              jobLink,
                              style: TextStyle(color: Colors.blue),
                            ),
                            onTap: () => _launchURL(jobLink),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getCourseLink(String subject) {
    return "https://www.coursera.org/search?query=$subject";
  }

  String _getTutorialLink(String subject) {
    return "https://www.youtube.com/results?search_query=$subject+tutorial";
  }

  String _getJobLink(String subject) {
    return "https://www.jobnet.com.mm/search?keyword=$subject";
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
