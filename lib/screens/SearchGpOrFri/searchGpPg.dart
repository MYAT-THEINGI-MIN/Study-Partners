import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/SearchGpOrFri/GroupCards.dart';
import 'package:sp_test/widgets/customSearchBar.dart';

class SearchGroupsPage extends StatefulWidget {
  const SearchGroupsPage({Key? key}) : super(key: key);

  @override
  _SearchGroupsPageState createState() => _SearchGroupsPageState();
}

class _SearchGroupsPageState extends State<SearchGroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchGroups);
  }

  Future<void> _searchGroups() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    print('Searching for: $query');

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('groupName', isGreaterThanOrEqualTo: query)
          .where('groupName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      print('Number of groups found: ${snapshot.docs.length}');

      setState(() {
        _searchResults = snapshot.docs;
      });
    } catch (e) {
      print('Error searching for groups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Groups'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomSearchBar(
              controller: _searchController,
              hintText: 'Enter Name',
              onChanged: (value) {},
              onIconPressed: _searchGroups,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: const Text('No groups found'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        var group = _searchResults[index];
                        Map<String, dynamic> groupData =
                            group.data() as Map<String, dynamic>;

                        // Use GroupCard widget to display each search result
                        return GroupCard(
                          profileUrl: groupData['profileUrl'],
                          groupName: groupData['groupName'],
                          subject: groupData['subject'],
                          groupId: group.id,
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
