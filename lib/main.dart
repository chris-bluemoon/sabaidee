import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/firebase_options.dart';
import 'package:sabaidee/home_page.dart';
import 'package:sabaidee/sign_in_page.dart';
import 'package:sabaidee/user_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
      log('User found in Firestore with uid: $uid');
      final userData = userDoc.data()!;
      final checkInTimes = (userData['checkInTimes'] as List).map((time) {
        return CheckInTime(
          dateTime: DateTime.parse(time['dateTime']),
          status: time['status'],
          duration: Duration(seconds: time['duration']),
        );
      }).toList();

      final relatives = (userData['relatives'] as List).map((relative) {
        return Map<String, String>.from(relative);
      }).toList();
      final watching = (userData['watching'] as List).map((watching) {
        return Map<String, String>.from(watching);
      }).toList();

      Provider.of<UserProvider>(context, listen: false).setUser(
        User(
          uid: uid,
          email: userData['email'],
          name: userData['name'],
          phoneNumber: userData['phoneNumber'],
          checkInTimes: checkInTimes,
          relatives: relatives,
          watching: watching,
          fcmToken: userData['fcmToken'],
        ),
      );
            // Get FCM token and update it
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        Provider.of<UserProvider>(context, listen: false).updateFcmToken(fcmToken);
      }
    } else {
      log('User not found in Firestore - redundant code/mismatch with Firebase?, should be not reached');
      // final firebaseUser = auth.FirebaseAuth.instance.currentUser;
      // if (firebaseUser != null) {
      //   final newUser = User(
      //     uid: uid,
      //     email: firebaseUser.email!,
      //     name: 'New User',
      //     phoneNumber: '',
      //     checkInTimes: [],
      //     relatives: [],
      //   );

      //   await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser.toFirestore());

      //   Provider.of<UserProvider>(context, listen: false).setUser(newUser);
      // }
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
          log('User is logged in as ${snapshot.data!.uid}');
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