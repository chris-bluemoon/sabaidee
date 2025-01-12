import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/screens/settings/add_schedule_page.dart';
import 'package:sabaidee/screens/settings/my_relatives_page.dart';
import 'package:sabaidee/screens/settings/notifications_page.dart';
import 'package:sabaidee/sign_in_page.dart';
import 'package:sabaidee/user_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSettingsOption(
              context,
              'Add Schedule',
              Icons.schedule,
              const AddSchedulePage(),
            ),
            const SizedBox(height: 10),
            _buildSettingsOption(
              context,
              'My Relatives',
              Icons.people,
              const MyRelativesPage(),
            ),
            const SizedBox(height: 10),
            _buildSettingsOption(
              context,
              'Notifications',
              Icons.notifications,
              const NotificationsPage(),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                await Provider.of<UserProvider>(context, listen: false).signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}