import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:sabaidee/settings/my_followers_page.dart';
import 'package:sabaidee/settings/my_schedule_page.dart';
import 'package:sabaidee/settings/my_watch_list.dart';
import 'package:sabaidee/settings/profile_page.dart'; // Import the ProfilePage

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // Initial value, adjust as needed

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05, // Adjust left padding
                screenHeight * 0.1, // Adjust top padding
                screenWidth * 0.05, // Adjust right padding
                screenHeight * 0.05, // Adjust bottom padding
              ), // Add margin at the top of the page
              child: Column(
                children: [
                  GlassmorphismContainer(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // Reduce padding above and below
                      itemCount: 4, // Show 4 items
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildSettingsOption(
                            context,
                            'My Schedule',
                            Icons.schedule_outlined,
                            const MySchedulePage(),
                            screenWidth,
                          );
                        } else if (index == 1) {
                          return _buildSettingsOption(
                            context,
                            'My Followers',
                            Icons.people_outline,
                            const MyFollowersPage(),
                            screenWidth,
                          );
                        } else if (index == 2) {
                          return _buildSettingsOption(
                            context,
                            'Who Am I Following?',
                            Icons.remove_red_eye_outlined, // Change to a pair of glasses icon
                            MyWatchList(),
                            screenWidth,
                          );
                        } else if (index == 3) {
                          return _buildSettingsOption(
                            context,
                            'Profile',
                            Icons.person_outline,
                            const ProfilePage(), // Navigate to ProfilePage
                            screenWidth,
                          );
                        }
                        return Container(); // Return an empty container for any other index
                      },
                      separatorBuilder: (context, index) => Column(
                        children: [
                          SizedBox(height: screenHeight * 0.01), // Add separation between items
                          const Divider(color: Colors.grey, height: 1), // Add a separator line
                          SizedBox(height: screenHeight * 0.01), // Add separation between items
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05), // Add some space between the containers
                  GlassmorphismContainer(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // Reduce padding above and below
                      children: [
                        ListTile(
                          leading: Icon(Icons.notifications_outlined, size: screenWidth * 0.055),
                          title: Text(
                            'Notifications',
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                            activeTrackColor: Colors.black,
                            inactiveTrackColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(), // Add a spacer to push the Sign Out option to the bottom
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.08), // Add more padding to avoid overlap with bottom nav bar
                    child: GlassmorphismContainer(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01), // Reduce padding above and below
                        children: [
                          ListTile(
                            leading: Icon(Icons.logout_outlined, size: screenWidth * 0.055),
                            title: Text(
                              'SIGN OUT',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            iconColor: Colors.black,
                            textColor: Colors.black,
                            onTap: () {
                              Provider.of<UserProvider>(context, listen: false).signOut();
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.delete_forever_outlined, size: screenWidth * 0.055, color: Colors.black),
                            title: Text(
                              'DELETE ACCOUNT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04, color: Colors.black),
                            ),
                            onTap: () async {
                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Deletion', textAlign: TextAlign.center),
                                    content: const Text('Are you sure you want to delete your account? This action cannot be undone.', textAlign: TextAlign.center),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('CANCEL', style: TextStyle(color: Colors.black)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('DELETE', style: TextStyle(color: Colors.black)),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                try {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Logged out and all data deleted.',
                                        style: TextStyle(fontSize: screenWidth * 0.04),
                                      ),
                                    ),
                                  );
                                  await userProvider.deleteAccountAndData();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete account: $e',
                                        style: TextStyle(fontSize: screenWidth * 0.04),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
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

  Widget _buildSettingsOption(BuildContext context, String title, IconData icon, Widget page, double screenWidth) {
    return ListTile(
      leading: Icon(icon, size: screenWidth * 0.055),
      title: Text(
        title,
        style: TextStyle(fontSize: screenWidth * 0.04),
      ),
      trailing: Icon(Icons.chevron_right_outlined, size: screenWidth * 0.055), // Add right chevron
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
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Reduce padding inside the container
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