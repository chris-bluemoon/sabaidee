import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/firebase_options.dart';
import 'package:sabaidee/home_page.dart';
import 'package:sabaidee/sign_in_page.dart';
import 'package:sabaidee/user_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling a background message: ${message.messageId}');

  final userProvider = navigatorKey.currentContext?.read<UserProvider>();
  if (userProvider != null && userProvider.user != null) {
    await userProvider.fetchUserData(userProvider.user!.uid);
    log('User data updated in background handler');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    log('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    log('User granted provisional permission');
  } else {
    log('User declined or has not accepted permission');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    AppleNotification? apple = message.notification?.apple;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: android != null
              ? const AndroidNotificationDetails(
                  'your_channel_id',
                  'your_channel_name',
                  channelDescription: 'your_channel_description',
                  icon: '@mipmap/ic_launcher',
                )
              : null,
          iOS: apple != null
              ? const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                )
              : null,
        ),
      );
      final userProvider = navigatorKey.currentContext?.read<UserProvider>();
      if (userProvider != null) {
        log('Notification received: ${message.data}');
        userProvider.handleNotification(message);
      }
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    try {
      await Provider.of<UserProvider>(context, listen: false).fetchUserData(uid);
    } catch (e) {
      log('Failed to fetch and set user: $e');
    }
  }

  Future<void> _updateFcmToken(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && userProvider.user != null) {
        await userProvider.updateFcmToken(userProvider.user!.uid, fcmToken);
        log('FCM token updated: $fcmToken');
      }
    } catch (e) {
      log('Failed to update FCM token: $e');
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
            await _updateFcmToken(context);
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