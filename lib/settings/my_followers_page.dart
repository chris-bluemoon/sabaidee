import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class MyFollowersPage extends StatefulWidget {
  const MyFollowersPage({super.key});

  @override
  _MyFollowersPageState createState() => _MyFollowersPageState();
}

class _MyFollowersPageState extends State<MyFollowersPage> {
  final TextEditingController _referralCodeController = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchRegisteredUsers(String currentUserUid) async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    return usersSnapshot.docs
        .map((doc) => {
              'uid': doc.id,
              ...doc.data(),
            })
        .where((user) => user['uid'] != currentUserUid) // Filter out the current user
        .toList();
  }

  Future<void> sendEmailWithInstructions(String code) async {
    final smtpServer = gmail(dotenv.env['SMTP_EMAIL']!, dotenv.env['SMTP_PASSWORD']!);
    final message = Message()
      ..from = const Address('info@unearthedcollections.com', 'Chris')
      ..recipients.add('chris.milner@gmail.com')
      ..subject = 'Instructions to Install the App'
      ..text = 'Please install the app and use the following code to register: $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } on MailerException catch (e) {
      print('Message not sent. ${e.toString()}');
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String?> _getUserNameFromUid(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data()?['name'];
    }
    return null;
  }

  Future<void> _submitReferralCode(BuildContext context, String code) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserUid = userProvider.user?.uid;

    if (currentUserUid == null) {
      print('Current user is not logged in.');
      return;
    }

    final users = await _fetchRegisteredUsers(currentUserUid);
    bool userFound = false;
    for (final user in users) {
      if (user['referralCode'] == code) {
        userFound = true;
        print('User found with referral code: $code');
        final existingFollowers = userProvider.followers;
        final followerAlreadyExists = existingFollowers.any((follower) => follower['uid'] == user['uid']);

        if (followerAlreadyExists) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Follower Already Exists'),
                content: const Text('This user is already added as a follower.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _referralCodeController.clear();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          final userName = await _getUserNameFromUid(user['uid']);
          userProvider.createRelationship(user['uid'], 'pending');
          print('User added as a follower.');
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Follower Added'),
                content: const Text('The user has been added as a follower.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.of(context).pop(); // Pop back to the previous screen
                    },
                  ),
                ],
              );
            },
          );
        }
        break;
      }
    }

    if (!userFound) {
      print('User not found');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid Code'),
            content: const Text('The referral code you entered is invalid.'),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      _referralCodeController.clear();
    }
  }

  Future<List<Map<String, String>>> _fetchFollowersWithNames(List<Map<String, String>> followers) async {
    List<Map<String, String>> followersWithNames = [];
    for (var follower in followers) {
      final name = await _getUserNameFromUid(follower['uid']!);
      followersWithNames.add({'uid': follower['uid']!, 'name': name ?? 'Unknown'});
    }
    return followersWithNames;
  }

  Future<void> _removeFollower(BuildContext context, String followerUid) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserUid = userProvider.user?.uid;

    if (currentUserUid == null) {
      print('Current user is not logged in.');
      return;
    }

    // Remove the follower from the user's followers list
    // await userProvider.removeFollower(followerUid);
    await userProvider.removeRelationship2(followerUid, 'pending');
    setState(() {}); // Refresh the screen
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final followers = userProvider.followers;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'MY FOLLOWERS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.pop(context); // Go back to the settings page
          },
        ),
      ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.04), // Add space below the app bar
                Expanded(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: _fetchFollowersWithNames(followers),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Error loading followers'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No Current Followers',
                                style: TextStyle(
                                  fontSize: 24, // Increase the font size
                                  fontWeight: FontWeight.bold, // Make the text bold
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () async {
                                  final code = _generateRandomCode();
                                  await sendEmailWithInstructions(code);
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Email Sent'),
                                        content: const Center(
                                          child: Text('Please check your email for the referral code and send to your friend!'),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text(
                                              'OK',
                                              style: TextStyle(color: Colors.black),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text(
                                  "Don't have a code yet? Receive an email",
                                  style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final followersWithNames = snapshot.data!;
                        return ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: followersWithNames.map((follower) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: screenHeight * 0.02), // Add padding between containers
                              child: Dismissible(
                                key: Key(follower['uid']!),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) async {
                                  await _removeFollower(context, follower['uid']!);
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete_outline, color: Colors.white),
                                ),
                                child: GlassmorphismContainer(
                                  height: screenWidth * 0.15, // Adjust height based on screen size
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(12.0, 6.0, 6.0, 6.0), // Increase the left padding slightly
                                        child: Text(
                                          follower['name']!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.05, // Set the font size relative to the screen width
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.black),
                                        onPressed: () async {
                                          await _removeFollower(context, follower['uid']!);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double height;

  const GlassmorphismContainer({required this.child, required this.height, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height, // Set a consistent height for each box
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Semi-transparent white
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Semi-transparent white border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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