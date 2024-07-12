import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/chatroomUserInfo.dart';
import 'package:sp_test/widgets/customSearchBar.dart';

class SearchFriPage extends StatefulWidget {
  const SearchFriPage({Key? key}) : super(key: key);

  @override
  _SearchFriPageState createState() => _SearchFriPageState();
}

class _SearchFriPageState extends State<SearchFriPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchUsers);
  }

  Future<void> _searchUsers() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      setState(() {
        _searchResults = snapshot.docs;
      });
    } catch (e) {
      print('Error searching for users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Friends'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomSearchBar(
              controller: _searchController,
              hintText: 'Enter Name',
              onChanged: (value) {},
              onIconPressed: _searchUsers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        var user = _searchResults[index];
                        Map<String, dynamic> userData =
                            user.data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                userData['profileUrl'] ??
                                    'https://via.placeholder.com/150',
                              ),
                            ),
                            title: Text(userData['username'] ?? 'No username'),
                            subtitle: Text(userData['email'] ?? 'No email'),
                            onTap: () {
                              // Navigate to ChatroomUserInfo when the card is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatroomUserInfo(
                                    userId: user.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
