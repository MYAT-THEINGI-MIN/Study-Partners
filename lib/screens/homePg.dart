import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/screens/Planner/plannerPg.dart';
import 'package:sp_test/screens/ProfilePg.dart';
import 'package:sp_test/screens/chatPg.dart';
import 'package:sp_test/screens/linkRCMpg.dart';
import 'package:sp_test/screens/SearchGpOrFri/searchPage.dart';
import 'package:sp_test/widgets/drawer.dart';

class HomePg extends StatefulWidget {
  @override
  _HomePgState createState() => _HomePgState();
}

class _HomePgState extends State<HomePg> {
  int _selectedIndex = 0;
  late String _profileImageUrl = '';
  late String _uid = '';

  List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _getCurrentUid().then((uid) {
      setState(() {
        _uid = uid;
        _widgetOptions = <Widget>[
          PlannerPage(),
          ChatPg(),
          SearchPage(),
          LinkRecommendationPage(uid: _uid), // Pass the UID here
        ];
      });
    });
  }

  Future<String> _getCurrentUid() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    return user?.uid ?? '';
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
        child: _widgetOptions.isNotEmpty
            ? _widgetOptions.elementAt(_selectedIndex)
            : CircularProgressIndicator(),
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
