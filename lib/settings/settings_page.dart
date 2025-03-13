import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/settings/my_followers_page.dart';
import 'package:sabaidee/settings/my_schedule_page.dart';
import 'package:sabaidee/settings/my_watch_list.dart';
import 'package:sabaidee/settings/profile_page.dart'; // Import the ProfilePage
import 'package:sabaidee/user_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // Initial value, adjust as needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg3.png',
              fit: BoxFit.cover,
            ),
          ),
          // Glassmorphism effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 50.0), // Add margin at the top of the page
              child: Column(
                children: [
                  GlassmorphismContainer(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 0), // Reduce padding above and below
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
                  const SizedBox(height: 16), // Add some space between the containers
                  GlassmorphismContainer(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8.0), // Reduce padding above and below
                      children: [
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notifications'),
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                              // Handle switch state change
                              if (_notificationsEnabled) {
                                // Enable notifications
                              } else {
                                // Disable notifications
                              }
                            },
                            activeTrackColor: Colors.black,
                            inactiveTrackColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(), // Add a spacer to push the Sign Out option to the bottom
                  GlassmorphismContainer(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 0), // Reduce padding above and below
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('SIGN OUT'),
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
        ],
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

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;

  const GlassmorphismContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 0),
          padding: const EdgeInsets.all(8.0), // Reduce padding inside the container
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Semi-transparent white
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Semi-transparent white border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}