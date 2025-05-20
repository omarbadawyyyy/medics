import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text(
                'Account Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account Settings tapped')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.blue),
              title: const Text(
                'Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications tapped')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: const Text(
                'Language',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language settings tapped')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.blue),
              title: const Text(
                'Privacy & Security',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy & Security tapped')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}