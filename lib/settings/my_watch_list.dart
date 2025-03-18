import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class MyWatchList extends StatelessWidget {
  const MyWatchList({super.key});

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

  Future<void> _submitReferralCode(BuildContext context, String code) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserUid = userProvider.user?.uid;

    if (currentUserUid == null) {
      print('Current user is not logged in.');
      _showDialog(context, 'Error', 'Current user is not logged in.');
      return;
    }

    final users = await _fetchRegisteredUsers(currentUserUid);
    bool userFound = false;
    for (final user in users) {
      if (user['referralCode'] == code) {
        userFound = true;
        print('User found with referral code: $code');
        final existingWatching = userProvider.watching;
        final watchingAlreadyExists = existingWatching.any((follower) => follower['uid'] == user['uid']);

        if (watchingAlreadyExists) {
          print('Watching already exists.');
          _showDialog(context, 'Follower Already Exists', 'This user is already added as a follower.');
        } else {
          userProvider.createRelationship(user['uid'], 'pending');
          print('User added as a follower.');
          _showDialog(context, 'Follower Added', 'The user has been added as a follower.');
        }
        break;
      }
    }

    if (!userFound) {
      print('User not found');
      _showDialog(context, 'Invalid Code', 'The referral code you entered is invalid.', isError: true);
    }
  }

  Future<String?> _getUserNameFromUid(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data()?['name'];
    }
    return null;
  }

  void _showReferralCodeDialog(BuildContext context) {
    final TextEditingController referralCodeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Invitation Code'),
          content: TextField(
            controller: referralCodeController,
            decoration: const InputDecoration(
              labelText: 'Invitation Code',
              labelStyle: TextStyle(color: Colors.black), // Set the label text color to black
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black), // Set the enabled border color to black
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black), // Set the focused border color to black
              ),
            ),
            style: const TextStyle(color: Colors.black), // Set the text color to black
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                final code = referralCodeController.text;
                Navigator.of(context).pop();
                await _submitReferralCode(context, code);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, String title, String content, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            content,
            style: TextStyle(color: isError ? Colors.red : Colors.black),
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
  }

  Future<void> _removeFollower(BuildContext context, String followerUid) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserUid = userProvider.user?.uid;

    if (currentUserUid == null) {
      print('Current user is not logged in.');
      return;
    }

    // Remove the follower from the user's watching list
    print('Follower ID $followerUid.');
    // await userProvider.removeFollower(followerUid);
    await userProvider.removeRelationship(followerUid, 'pending');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final watchings = userProvider.watching;
    final currentUserUid = userProvider.user?.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('FOLLOWING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05)),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
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
                SizedBox(height: screenHeight * 0.04), // Reduce space below the app bar
                Expanded(
                  child: FutureBuilder<Map<String, Map<String, String>>>(
                    future: userProvider.fetchWatchingNamesAndStatuses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(child: Text('Something went wrong'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0), // Add padding around the text
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, // Center the text vertically
                              children: [
                                Text(
                                  'Not Currently Following Anyone',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24, // Increase the font size
                                    fontWeight: FontWeight.bold, // Make the text bold
                                  ),
                                ),
                                SizedBox(height: 8.0), // Add some space between the texts
                                Text(
                                  '(Click add button below to add a friend who has provided an invitation code)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16, // Set the font size
                                    color: Colors.black54, // Set the text color
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        final watchingNamesAndStatuses = snapshot.data!;
                        return ListView.builder(
                          itemCount: watchings.length,
                          itemBuilder: (context, index) {
                            final watching = watchings[index];
                            final watchingUid = watching['uid'];
                            final watchingName = watchingNamesAndStatuses[watchingUid]?['name'] ?? 'Unknown';
                            final watchingStatus = watchingNamesAndStatuses[watchingUid]?['status'] ?? 'Unknown';
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: screenHeight * 0.01), // Add horizontal padding and vertical padding between containers
                              child: Dismissible(
                                key: Key(watchingUid!),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) async {
                                  await _removeFollower(context, watchingUid);
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
                                          watchingName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.05, // Set the font size relative to the screen width
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.black),
                                        iconSize: screenWidth * 0.07, // Set the icon size relative to the screen width
                                        onPressed: () async {
                                          await _removeFollower(context, watchingUid);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showReferralCodeDialog(context);
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
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