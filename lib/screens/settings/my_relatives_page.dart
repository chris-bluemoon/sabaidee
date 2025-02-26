import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class MyRelativesPage extends StatelessWidget {
  MyRelativesPage({super.key});

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
        final existingRelatives = userProvider.relatives;
        final relativeAlreadyExists = existingRelatives.any((relative) => relative['uid'] == user['uid']);

        if (relativeAlreadyExists) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Relative Already Exists'),
                content: const Text('This user is already added as a relative.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
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
          userProvider.addRelative(user['uid'], 'pending');
          print('User added as a relative.');
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Relative Added'),
                content: const Text('The user has been added as a relative.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
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
                child: const Text('OK'),
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

  Future<List<Map<String, String>>> _fetchRelativesWithNames(List<Map<String, String>> relatives) async {
    List<Map<String, String>> relativesWithNames = [];
    for (var relative in relatives) {
      final name = await _getUserNameFromUid(relative['uid']!);
      relativesWithNames.add({'uid': relative['uid']!, 'name': name ?? 'Unknown'});
    }
    return relativesWithNames;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final relatives = userProvider.relatives;
    final currentUserUid = userProvider.user?.uid;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('My Relatives'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _fetchRelativesWithNames(relatives),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading relatives'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No current relatives'));
          } else {
            final relativesWithNames = snapshot.data!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: relativesWithNames.map((relative) {
                      return Text('Relative Name: ${relative['name']}');
                    }).toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = _generateRandomCode();
                    await sendEmailWithInstructions(code);
                  },
                  child: const Text('Receive Email'),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _referralCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Referral Code',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = _referralCodeController.text;
                    await _submitReferralCode(context, code);
                  },
                  child: const Text('Submit Referral Code'),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}