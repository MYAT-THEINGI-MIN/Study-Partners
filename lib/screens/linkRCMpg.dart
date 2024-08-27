import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkRecommendationPage extends StatefulWidget {
  @override
  _LinkRecommendationPageState createState() => _LinkRecommendationPageState();
}

class _LinkRecommendationPageState extends State<LinkRecommendationPage> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPopularLinks() async {
    try {
      final querySnapshot = await _firebaseFirestore
          .collection('LinksRecommendation')
          .orderBy('count', descending: true) // Sort by popularity
          .limit(10) // Limit the number of results to 20
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching popular links: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Popular Study Links'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Refresh the data
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getPopularLinks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching links.'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No popular links available.'));
            }

            final popularLinks = snapshot.data!;

            return ListView.builder(
              itemCount: popularLinks.length,
              itemBuilder: (context, index) {
                final link = popularLinks[index];
                final domain = link['domain'] as String;
                final count = link['count'] as int;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(Icons.link, color: Colors.blue),
                    title: Text(
                      domain,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Popularity: $count'),
                    onTap: () {
                      // Optionally, launch the link or show more details
                      _launchURL(domain);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _launchURL(String domain) async {
    final url = Uri.parse('https://$domain');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
