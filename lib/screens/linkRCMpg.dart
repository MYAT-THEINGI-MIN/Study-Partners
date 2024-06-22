import 'package:flutter/material.dart';

class LinkRecommendationPage extends StatefulWidget {
  const LinkRecommendationPage({Key? key}) : super(key: key);

  @override
  _LinkRecommendationPageState createState() => _LinkRecommendationPageState();
}

class _LinkRecommendationPageState extends State<LinkRecommendationPage> {
  final TextEditingController _topicController = TextEditingController();
  final List<String> _recommendations = [];
  final Map<String, List<String>> _linksDatabase = {
    'flutter': [
      'https://flutter.dev/',
      'https://docs.flutter.dev/',
      'https://github.com/flutter/flutter',
    ],
    'dart': [
      'https://dart.dev/',
      'https://dart.dev/guides',
      'https://github.com/dart-lang/sdk',
    ],
    'firebase': [
      'https://firebase.google.com/',
      'https://firebase.google.com/docs',
      'https://github.com/firebase/firebase-ios-sdk',
    ],
  };

  void _getRecommendations(String topic) {
    setState(() {
      _recommendations.clear();
      _recommendations.addAll(_linksDatabase[topic.toLowerCase()] ?? []);
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Link Recommendations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Enter a topic',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _getRecommendations(_topicController.text),
                ),
              ),
              onSubmitted: (value) => _getRecommendations(value),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_recommendations[index]),
                    onTap: () {
                      // Handle link tap, e.g., open in a web browser
                      _openLink(_recommendations[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLink(String url) {
    // Logic to open the URL
    // You can use the `url_launcher` package to launch URLs
    // import 'package:url_launcher/url_launcher.dart';
    // launch(url);
  }
}
