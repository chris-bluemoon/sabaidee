import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/home_page.dart';
import 'package:sabaidee/sign_in_page.dart';
import 'package:sabaidee/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        title: 'Sabaidee',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _fetchAndSetUser(BuildContext context, String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final checkInTimes = (userData['checkInTimes'] as List).map((time) {
        return CheckInTime(
          time: TimeOfDay(hour: time['hour'], minute: time['minute']),
          status: time['status'],
        );
      }).toList();

      Provider.of<UserProvider>(context, listen: false).setUser(
        User(
          uid: uid,
          email: userData['email'],
          name: userData['name'],
          phoneNumber: userData['phoneNumber'],
          checkInTimes: checkInTimes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        } else if (snapshot.hasData) {
          // User is logged in
          log('User is logge in');  
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _fetchAndSetUser(context, snapshot.data!.uid);
          });
          return const HomePage();
        } else {
          // User is not logged in
          return const SignInPage();
        }
      },
    );
  }
}