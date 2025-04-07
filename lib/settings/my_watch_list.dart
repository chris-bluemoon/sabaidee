import 'dart:developer';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:sabaidee/settings/watching_detail.dart';

class MyWatchList extends StatefulWidget {
  const MyWatchList({super.key});

  @override
  _MyWatchListState createState() => _MyWatchListState();
}

class _MyWatchListState extends State<MyWatchList> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
      log('Error: Current user is not logged in.');
      return;
    }

    try {
      final users = await _fetchRegisteredUsers(currentUserUid);
      bool userFound = false;

      for (final user in users) {
        if (user['referralCode'] == code) {
          userFound = true;
          log('User found with referral code: $code');
          final existingWatching = userProvider.watching;
          final watchingAlreadyExists = existingWatching.any((follower) => follower['uid'] == user['uid']);

          if (watchingAlreadyExists) {
            log('Info: You are already watching this person.');
          } else {
            await userProvider.createRelationship(user['uid'], 'pending');
            log('Success: User added as a follower.');
          }
          break;
        }
      }

      if (!userFound) {
        log('Invalid Code: The referral code you entered is invalid.');
      }
    } catch (e) {
      log('Error: An error occurred while checking the referral code. Details: $e');
    }
  }

  Future<String?> _getUserNameFromUid(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data()?['name'];
    }
    return null;
  }

  Future<String?> _getLastCheckInStatus(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final statuses = userDoc.data()?['checkInTimes'] as List<dynamic>?;
        log('Statuses: $statuses');
        if (statuses != null && statuses.isNotEmpty) {
          final filteredStatuses = statuses.where((status) => status['status'] != 'pending').toList();
          if (filteredStatuses.isNotEmpty) {
            filteredStatuses.sort((a, b) {
              final aTimestamp = a['dateTime'] is Timestamp ? a['dateTime'] as Timestamp : Timestamp.fromDate(DateTime.parse(a['dateTime']));
              final bTimestamp = b['dateTime'] is Timestamp ? b['dateTime'] as Timestamp : Timestamp.fromDate(DateTime.parse(b['dateTime']));
              return bTimestamp.compareTo(aTimestamp);
            });
            return filteredStatuses.first['status'] as String?;
          } else {
            log('Filtered statuses list is empty');
          }
        } else {
          log('Statuses list is empty or null');
        }
      } else {
        log('User document does not exist for UID: $uid');
      }
    } catch (e) {
      log('Error fetching last check-in status: $e');
    }
    return 'TBC';
  }

  void _showReferralCodeDialog(BuildContext context) {
    final TextEditingController referralCodeController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Enter Invitation Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: referralCodeController,
                    decoration: InputDecoration(
                      labelText: 'Invitation Code',
                      labelStyle: const TextStyle(color: Colors.black),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      errorText: errorText, // Display error text if set
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
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
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final currentUserUid = userProvider.user?.uid;

                    if (currentUserUid == null) {
                      setState(() {
                        errorText = 'Invalid Code';
                      });
                      return;
                    }

                    final users = await _fetchRegisteredUsers(currentUserUid);
                    final userFound = users.any((user) => user['referralCode'] == code);

                    if (userFound) {
                      Navigator.of(context).pop();
                      await _submitReferralCode(context, code);
                    } else {
                      setState(() {
                        errorText = 'Invalid Code';
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeFollower(BuildContext context, String followerUid) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserUid = userProvider.user?.uid;

    if (currentUserUid == null) {
      print('Current user is not logged in.');
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Current user is not logged in.')),
        );
      }
      return;
    }

    // Remove the follower from the user's watching list
    print('Follower ID $followerUid.');
    await userProvider.removeRelationship(followerUid, 'pending');
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Follower removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final watchings = userProvider.watching;
    final currentUserUid = userProvider.user?.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
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
                    child: FutureBuilder<Map<String, Map<String, dynamic>>>(
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
                              final watchingCreatedAt = watching['createdAt'];
                              final watchingName = watchingNamesAndStatuses[watchingUid]?['name'] ?? 'Unknown';
                              final createdAtString = watchingNamesAndStatuses[watchingUid]?['createdAt'];
                              final createdAtTimestamp = DateTime.parse(createdAtString);
                              final formattedCreatedAt = DateFormat("yyyy-MM-dd").format(createdAtTimestamp);
                              final createdAt = formattedCreatedAt;
                              return FutureBuilder<String?>(
                                future: _getLastCheckInStatus(watchingUid!),
                                builder: (context, statusSnapshot) {
                                  if (statusSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (statusSnapshot.hasError) {
                                    log('Error in FutureBuilder: ${statusSnapshot.error}');
                                    return const Center(child: Text('Error fetching status'));
                                  } else {
                                    final lastCheckInStatus = statusSnapshot.data ?? 'Unknown snapshot data';
                                    final displayStatus = (lastCheckInStatus == 'missed' || lastCheckInStatus == 'checked in')
                                        ? lastCheckInStatus.toUpperCase()
                                        : 'TBC';
                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: screenHeight * 0.01), // Add horizontal padding and vertical padding between containers
                                      child: GestureDetector(
                                        onTap: () {
                                          // Navigate to the watching_detail page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => WatchingDetail(
                                                watchingUid: watchingUid,
                                              ),
                                            ),
                                          );
                                        },
                                        child: GlassmorphismContainer(
                                          height: screenHeight * 0.15, // Adjust height for the container
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Left side: User information
                                              Padding(
                                                padding: EdgeInsets.fromLTRB(
                                                  screenWidth * 0.02, // Left padding
                                                  screenHeight * 0.01, // Top padding
                                                  0.0, // Right padding
                                                  screenHeight * 0.01, // Bottom padding
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      watchingName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: screenWidth * 0.05, // Set the font size relative to the screen width
                                                      ),
                                                    ),
                                                    SizedBox(height: screenHeight * 0.005),
                                                    Text(
                                                      'Following since: $createdAt',
                                                      style: TextStyle(
                                                        fontSize: screenWidth * 0.035, // Set the font size relative to the screen width
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(height: screenHeight * 0.005),
                                                    Text(
                                                      'Last check-in status: $displayStatus',
                                                      style: TextStyle(
                                                        fontSize: screenWidth * 0.035, // Set the font size relative to the screen width
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Right side: Chevron icon
                                              Padding(
                                                padding: EdgeInsets.only(right: screenWidth * 0.02), // Right padding for the chevron
                                                child: Icon(
                                                  Icons.chevron_right,
                                                  size: screenWidth * 0.07, // Set the icon size relative to the screen width
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
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