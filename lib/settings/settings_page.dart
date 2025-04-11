import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:sabaidee/settings/my_followers_page.dart';
import 'package:sabaidee/settings/my_schedule_page.dart';
import 'package:sabaidee/settings/my_watch_list.dart';
import 'package:sabaidee/settings/profile_page.dart'; // Import the ProfilePage
import 'package:sabaidee/sign_in_page.dart'; // Import the SignInPage
import 'package:sabaidee/sign_up_page.dart'; // Import the SignUpPage

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // Initial value, adjust as needed
  bool _emojisEnabled = true; // Default value, will be updated in initState
  bool _quotesEnabled = true; // Default value for quotes
  bool _locationSharingEnabled = false; // Add this variable to track location sharing state

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _emojisEnabled = userProvider.user?.emojisEnabled ?? true; // Load emojisEnabled from _user
    _quotesEnabled = userProvider.user?.quotesEnabled ?? true; // Load quotesEnabled from _user
    _locationSharingEnabled = userProvider.user?.locationSharingEnabled ?? false; // Load locationSharingEnabled from _user
  }

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
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.05, // Adjust left padding
                  screenHeight * 0.05, // Adjust top padding
                  screenWidth * 0.05, // Adjust right padding
                  screenHeight * 0.05, // Adjust bottom padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassmorphismContainer(
                      child: SizedBox(
                        height: screenHeight * 0.4, // Constrain the height of the ListView
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
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
                                Icons.remove_red_eye_outlined,
                                const MyWatchList(),
                                screenWidth,
                              );
                            } else if (index == 3) {
                              return _buildSettingsOption(
                                context,
                                'Profile',
                                Icons.person_outline,
                                const ProfilePage(),
                                screenWidth,
                              );
                            }
                            return Container();
                          },
                          separatorBuilder: (context, index) => Column(
                            children: [
                              SizedBox(height: screenHeight * 0.01),
                              const Divider(color: Colors.grey, height: 1),
                              SizedBox(height: screenHeight * 0.01),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    GlassmorphismContainer(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
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
                          const Divider(color: Colors.grey, height: 1),
                          ListTile(
                            leading: Icon(Icons.location_on_outlined, size: screenWidth * 0.055),
                            title: Text(
                              'Share Location',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            trailing: Switch(
                              value: _locationSharingEnabled,
                              onChanged: (bool value) async {
                                setState(() {
                                  _locationSharingEnabled = value;
                                });

                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                if (userProvider.user != null) {
                                  userProvider.user!.locationSharingEnabled = value;
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userProvider.user!.uid)
                                      .update({'locationSharingEnabled': value});
                                }
                              },
                              activeTrackColor: Colors.black,
                              inactiveTrackColor: Colors.black,
                            ),
                          ),
                          const Divider(color: Colors.grey, height: 1),
                          ListTile(
                            leading: Icon(Icons.emoji_emotions_outlined, size: screenWidth * 0.055),
                            title: Text(
                              'Emojis',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            trailing: Switch(
                              value: _emojisEnabled,
                              onChanged: (bool value) async {
                                setState(() {
                                  _emojisEnabled = value;
                                });

                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                if (userProvider.user != null) {
                                  userProvider.user!.emojisEnabled = value;
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userProvider.user!.uid)
                                      .update({'emojisEnabled': value});
                                }
                              },
                              activeTrackColor: Colors.black,
                              inactiveTrackColor: Colors.black,
                            ),
                          ),
                          const Divider(color: Colors.grey, height: 1),
                          ListTile(
                            leading: Icon(Icons.format_quote_outlined, size: screenWidth * 0.055),
                            title: Text(
                              'Quotes',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            trailing: Switch(
                              value: _quotesEnabled,
                              onChanged: (bool value) async {
                                setState(() {
                                  _quotesEnabled = value;
                                });

                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                if (userProvider.user != null) {
                                  userProvider.user!.quotesEnabled = value;
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userProvider.user!.uid)
                                      .update({'quotesEnabled': value});
                                }
                              },
                              activeTrackColor: Colors.black,
                              inactiveTrackColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    GlassmorphismContainer(
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
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
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const SignInPage()),
                                (route) => false, // Remove all previous routes
                              );
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
                                    content: const Text(
                                      'Are you sure you want to delete your account? This action cannot be undone.',
                                      textAlign: TextAlign.center,
                                    ),
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
                                // Show spinner while deleting account
                                showDialog(
                                  context: context,
                                  barrierDismissible: false, // Prevent dismissing the dialog
                                  builder: (context) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );

                                try {
                                  await userProvider.deleteAccountAndData();

                                  // Close the spinner
                                  Navigator.of(context).pop();

                                  // Redirect to SignUpPage after deletion
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                                    (route) => false, // Remove all previous routes
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Account deleted successfully.',
                                        style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  // Close the spinner
                                  Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to delete account: $e',
                                        style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
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
                  ],
                ),
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