import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';
import 'package:sabaidee/utils/settings/my_followers_page.dart';
import 'package:sabaidee/utils/settings/my_schedule_page.dart';
import 'package:sabaidee/utils/settings/my_watch_list.dart';
import 'package:sabaidee/utils/settings/profile_page.dart'; // Import the ProfilePage

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final watchings = userProvider.watching;

    return Scaffold(
      backgroundColor: Colors.yellow,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0), // Move the container down by 50 pixels
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.yellow, // Set the background color to yellow
                  borderRadius: BorderRadius.circular(16.0), // Add rounded corners
                ),
                margin: const EdgeInsets.all(16.0),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: 4, // Show 4 items
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSettingsOption(
                        context,
                        'My Followers',
                        Icons.people,
                        const MyFollowersPage(),
                      );
                    } else if (index == 1) {
                      return _buildSettingsOption(
                        context,
                        'My Schedule',
                        Icons.schedule,
                        const MySchedulePage(),
                      );
                    } else if (index == 2) {
                      return _buildSettingsOption(
                        context,
                        'Who Am I Following?',
                        Icons.watch_later,
                        const MyWatchList(),
                      );
                    } else if (index == 3) {
                      return _buildSettingsOption(
                        context,
                        'Profile',
                        Icons.person,
                        const ProfilePage(), // Navigate to ProfilePage
                      );
                    }
                    return Container(); // Return an empty container for any other index
                  },
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.grey,
                    height: 1,
                  ),
                ),
              ),
              const Spacer(), // Add a spacer to push the Sign Out option to the bottom
              Container(
                decoration: BoxDecoration(
                  color: Colors.yellow, // Set the background color to yellow
                  borderRadius: BorderRadius.circular(16.0), // Add rounded corners
                ),
                margin: const EdgeInsets.all(16.0),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Sign Out'),
                      iconColor: Colors.black,
                      textColor: Colors.black,
                      onTap: () {
                        Provider.of<UserProvider>(context, listen: false).signOut();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption(BuildContext context, String title, IconData icon, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right), // Add right chevron
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}