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
    await userProvider.removeFollower(followerUid);

    print('Follower removed.');
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
            size: screenWidth * 0.08, // Set the size relative to the screen width
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
                return Dismissible(
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
                  child: ListTile(
                    title: Container(
                      padding: const EdgeInsets.fromLTRB(12.0, 6.0, 6.0, 6.0), // Increase the left padding slightly
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            watchingName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.05, // Set the font size relative to the screen width
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.black),
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