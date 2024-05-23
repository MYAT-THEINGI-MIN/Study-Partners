import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sp_test/screens/PlannerPg.dart';
import 'package:sp_test/screens/aboutMe.dart';
import 'loginPg.dart';
import 'chatUserListPg.dart';

class homePg extends StatefulWidget {
  @override
  _HomePgState createState() => _HomePgState();
}

class _HomePgState extends State<homePg> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    PlannerPage(),
    ChatUserListPg(),
    ProfilePg(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPg()),
      );
    } catch (e) {
      print('Failed to sign out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 114, 70, 226),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('AboutMe'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutMePg()),
                );
              },
            )
          ],
        ),
      ),
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 176, 95, 227),
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProfilePg extends StatelessWidget {
  const ProfilePg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: const Text("This is Profile Section"));
  }
}
