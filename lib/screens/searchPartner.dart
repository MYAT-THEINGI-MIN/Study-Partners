import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SearchPartnerPg(),
    );
  }
}

class SearchPartnerPg extends StatefulWidget {
  @override
  _SearchPartnerPgState createState() => _SearchPartnerPgState();
}

class _SearchPartnerPgState extends State<SearchPartnerPg> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText:
                'Search by ${_searchMode == SearchMode.name ? 'name' : 'subjects'}',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            onPressed: () {
              setState(() {
                _searchMode = _searchMode == SearchMode.name
                    ? SearchMode.subjects
                    : SearchMode.name;
                _searchQuery = '';
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _searchMode == SearchMode.name
              ? usersCollection
                  .where('username',
                      isGreaterThanOrEqualTo: _searchQuery,
                      isLessThanOrEqualTo: _searchQuery + '\uf8ff')
                  .snapshots()
              : usersCollection
                  .where('subjects', arrayContains: _searchQuery.toLowerCase())
                  .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No partners found'));
            }

            var partners = snapshot.data!.docs;

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns
                childAspectRatio: 0.7, // Adjust the aspect ratio as needed
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: partners.length,
              itemBuilder: (context, index) {
                var partner = partners[index];
                return Card(
                  child: Column(
                    children: [
                      Expanded(child: buildPartnerInfo(partner)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildPartnerInfo(DocumentSnapshot partner) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: partner['profileImageUrl'] != null
              ? NetworkImage(partner['profileImageUrl'])
              : null,
          backgroundColor: Colors.grey[300],
          child: partner['profileImageUrl'] == null
              ? Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey[700],
                )
              : null,
        ),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner['username'] ?? 'No Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                partner['subjects'] ?? 'No Subjects',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum SearchMode {
  name,
  subjects,
}
