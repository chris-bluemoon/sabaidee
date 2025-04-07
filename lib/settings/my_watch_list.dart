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
  late Future<Map<String, Map<String, dynamic>>> _watchingDataFuture;

  @override
  void initState() {
    super.initState();
    _watchingDataFuture = _fetchWatchingData();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchWatchingData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final watchings = userProvider.watching;

    final Map<String, Map<String, dynamic>> watchingData = {};
    for (final watching in watchings) {
      final watchingUid = watching['uid'];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(watchingUid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final checkInTimes = data['checkInTimes'] as List<dynamic>? ?? [];
        final filteredStatuses = checkInTimes.where((status) => status['status'] != 'pending').toList();

        String lastCheckInStatus = 'TBC';
        if (filteredStatuses.isNotEmpty) {
          filteredStatuses.sort((a, b) {
            final aTimestamp = a['dateTime'] is Timestamp ? a['dateTime'] as Timestamp : Timestamp.fromDate(DateTime.parse(a['dateTime']));
            final bTimestamp = b['dateTime'] is Timestamp ? b['dateTime'] as Timestamp : Timestamp.fromDate(DateTime.parse(b['dateTime']));
            return bTimestamp.compareTo(aTimestamp);
          });
          lastCheckInStatus = filteredStatuses.first['status'] as String? ?? 'TBC';
        }

        // Parse and format the createdAt field from the watching field
        String formattedCreatedAt = 'Unknown';
        if (watching['createdAt'] != null) {
          try {
            final createdAtTimestamp = watching['createdAt'] is Timestamp
                ? (watching['createdAt'] as Timestamp).toDate()
                : DateTime.parse(watching['createdAt'] ?? '');
            formattedCreatedAt = _formatDateWithSuffix(createdAtTimestamp);
          } catch (e) {
            log('Error parsing createdAt field for $watchingUid: $e');
          }
        }

        if (watchingUid != null) {
          watchingData[watchingUid] = {
            'name': data['name'] ?? 'Unknown',
            'createdAt': formattedCreatedAt, // Use the formatted date
            'lastCheckInStatus': lastCheckInStatus,
          };
        }
      }
    }
    return watchingData;
  }

  // Helper function to format the date with a suffix
  String _formatDateWithSuffix(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final formattedDate = DateFormat("d'$suffix' MMMM, yyyy").format(date);
    return formattedDate;
  }

  // Helper function to get the day suffix (e.g., 'st', 'nd', 'rd', 'th')
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

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
              size: screenWidth * 0.08,
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
                  SizedBox(height: screenHeight * 0.04),
                  Expanded(
                    child: FutureBuilder<Map<String, Map<String, dynamic>>>(
                      future: _watchingDataFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return const Center(child: Text('Something went wrong'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Not Currently Following Anyone',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    '(Click add button below to add a friend who has provided an invitation code)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          final watchingData = snapshot.data!;
                          return ListView.builder(
                            itemCount: watchingData.length,
                            itemBuilder: (context, index) {
                              final watchingUid = watchingData.keys.elementAt(index);
                              final watching = watchingData[watchingUid]!;
                              final watchingName = watching['name'];
                              final createdAt = watching['createdAt'];
                              final lastCheckInStatus = watching['lastCheckInStatus'];

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: screenHeight * 0.01),
                                child: GestureDetector(
                                  onTap: () {
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
                                    height: screenHeight * 0.15,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Left side: User information
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            screenWidth * 0.02,
                                            screenHeight * 0.01,
                                            0.0,
                                            screenHeight * 0.01,
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                watchingName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: screenWidth * 0.05,
                                                ),
                                              ),
                                              SizedBox(height: screenHeight * 0.005),
                                              Text(
                                                'Following since: $createdAt',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.035,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: screenHeight * 0.005),
                                              Text(
                                                'Last check-in status: $lastCheckInStatus',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.035,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Right side: Chevron icon
                                        Padding(
                                          padding: EdgeInsets.only(right: screenWidth * 0.02),
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: screenWidth * 0.07,
                                            color: Colors.black,
                                          ),
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
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}