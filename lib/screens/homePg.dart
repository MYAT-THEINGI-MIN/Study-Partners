import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/Planner/plannerPg.dart';
import 'package:sp_test/screens/ProfilePg.dart';
import 'package:sp_test/screens/chatUserListPg.dart';
import 'package:sp_test/screens/linkRCMpg.dart';
import 'package:sp_test/screens/searchPartner.dart';
import 'package:sp_test/widgets/drawer.dart';

class HomePg extends StatefulWidget {
  @override
  _HomePgState createState() => _HomePgState();
}

class _HomePgState extends State<HomePg> {
  int _selectedIndex = 0;
  late String _profileImageUrl = '';

  static final List<Widget> _widgetOptions = <Widget>[
    PlannerPage(),
    ChatUserListPg(),
    SearchPartnerPg(),
    LinkRecommendationPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onProfileTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePg()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> userProfile =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        _profileImageUrl = userProfile.data()?['profileImageUrl'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("Home Page"),
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.deepPurple
                .shade100 // Set app bar color to white in light theme
            : Colors
                .deepPurple, // Set app bar color to deep purple in dark theme
        actions: <Widget>[
          IconButton(
            icon: _profileImageUrl.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(_profileImageUrl),
                  )
                : CircleAvatar(
                    child: Icon(Icons.person),
                  ),
            onPressed: _onProfileTapped,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_day_rounded),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: 'Link',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor:
            Colors.grey, // Set the unselected item color to grey
        onTap: _onItemTapped,
      ),
    );
  }
}
