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
      return;
    }

    final users = await _fetchRegisteredUsers(currentUserUid);
    bool userFound = false;
    for (final user in users) {
      if (user['referralCode'] == code) {
        userFound = true;
        print('User found with referral code: $code');
        final existingfollowers = userProvider.followers;
        final followerAlreadyExists = existingfollowers.any((follower) => follower['uid'] == user['uid']);

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
                    },
                  ),
                ],
              );
            },
          );
        } else {
          userProvider.createRelationship(user['uid'], 'pending');
          print('User added as a follower.');
          Navigator.of(context).pop(); // Pop back to the previous screen
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
                      // Navigator.of(context).pop(); // Pop back to the previous screen
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
                await _submitReferralCode(context, code);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final watchings = userProvider.watching;
    final currentUserUid = userProvider.user?.uid;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('FOLLOWING', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size follower to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, Map<String, String>>>(
        future: userProvider.fetchWatchingNamesAndStatuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Not currently following'));
          } else {
            final watchingNamesAndStatuses = snapshot.data!;
            return ListView.builder(
              itemCount: watchings.length,
              itemBuilder: (context, index) {
                final watching = watchings[index];
                final watchingUid = watching['uid'];
                final watchingName = watchingNamesAndStatuses[watchingUid]?['name'] ?? 'Unknown';
                final watchingStatus = watchingNamesAndStatuses[watchingUid]?['status'] ?? 'Unknown';
                return ListTile(
                  title: Text('Name: $watchingName'),
                  subtitle: Text('Status: $watchingStatus'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Handle delete follower
                    },
                  ),
                );
              },
            );
          }
        },
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