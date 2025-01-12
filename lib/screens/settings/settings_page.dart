import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/screens/settings/add_schedule_page.dart';
import 'package:sabaidee/screens/settings/my_relatives_page.dart';
import 'package:sabaidee/user_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0), // Move the container down by 50 pixels
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0), // Add rounded corners
                ),
                margin: const EdgeInsets.all(16.0),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: 2, // Update this count based on the number of options
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSettingsOption(
                        context,
                        'My Relatives',
                        Icons.people,
                        const MyRelativesPage(),
                      );
                    } else if (index == 1) {
                      return _buildSettingsOption(
                        context,
                        'Add Schedule',
                        Icons.schedule,
                        const AddSchedulePage(),
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      iconColor: Colors.red,
                      textColor: Colors.red,
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