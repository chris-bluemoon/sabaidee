import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/screens/background_widget.dart';
import 'package:sabaidee/screens/settings/add_schedule_page.dart';
import 'package:sabaidee/screens/settings/my_relatives_page.dart';
import 'package:sabaidee/screens/settings/notifications_page.dart';
import 'package:sabaidee/sign_in_page.dart';
import 'package:sabaidee/user_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsOption(
            context,
            'My Relatives',
            Icons.people,
            const MyRelativesPage(),
          ),
          const SizedBox(height: 10),
          _buildSettingsOption(
            context,
            'Add A Schedule',
            Icons.timer,
            const AddSchedulePage(),
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
              backgroundColor: const Color(0xFFDF6D2D), // Set the button color to #DF6D2D
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Less rounded corners
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context, String title, IconData icon, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(color: Theme.of(context).primaryColor)),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}