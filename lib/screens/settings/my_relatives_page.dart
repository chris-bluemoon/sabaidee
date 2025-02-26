import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class MyRelativesPage extends StatelessWidget {
  const MyRelativesPage({super.key});

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
  final smtpServer = gmail('chris@unearthedcollections.com', 'your_password');
  final message = Message()
    ..from = const Address('your_email@gmail.com', 'Your Name')
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
    body: Column(
      children: [
        // Existing code to display relatives
        ElevatedButton(
          onPressed: () async {
            final code = _generateRandomCode();
            await sendEmailWithInstructions(code);
          },
          child: const Text('Receive Email'),
        ),
      ],
    ),
  );
}


}