import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sp_test/Service/themeProvider.dart';
import 'package:sp_test/screens/GpChat/createGp.dart';
import 'package:sp_test/screens/PrivacyPolicyPg.dart';
import 'package:sp_test/screens/aboutMe.dart';
import 'package:sp_test/screens/loginPg.dart';
import 'package:sp_test/screens/userGuidePg.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

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

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data();
    } catch (e) {
      print('Failed to fetch user data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching user data'));
          }

          final userData = snapshot.data;
          final userName = userData?['username'] ?? 'User';
          final userEmail = userData?['email'] ?? 'No email provided';

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                accountEmail: Text(
                  userEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(userData?['profileImageUrl'] ??
                      'https://via.placeholder.com/150'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(
                  'Change Theme',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: Text(
                  'Create Group',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateGroup()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(
                  'About Me',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutMePg()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: Text(
                  'User Guide',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserGuidePg()),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.privacy_tip), // Update the icon if needed
                title: Text(
                  'Privacy and Policy',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(
                  'Logout',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () => _logout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
