import 'dart:convert'; // Add this import for JSON decoding
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/firebase_options.dart';
import 'package:sabaidee/home_page.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:sabaidee/settings/profile_page.dart';
import 'package:sabaidee/settings/settings_page.dart';
import 'package:sabaidee/sign_in_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point') // Add this annotation
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling a background message: $message.toString()}');
  log('Background message data: ${message.data}');
  log('Background message notification: ${message.notification?.title}');

  final userProvider = navigatorKey.currentContext?.read<UserProvider>();
  if (userProvider != null && userProvider.user != null) {
    await userProvider.fetchUserData(userProvider.user!.uid);
    log('User data updated in background handler');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterNativeSplash.remove();

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
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      log('Notification tapped!');
      if (response.payload != null) {
        log('Notification payload: ${response.payload}'); // Log the raw payload

        try {
          // Decode the JSON payload
          final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
          log('Decoded payload data: $payloadData');

          // Check if the payload contains a specific key to navigate
          if (payloadData['data']['status'] == 'missed') {
            navigatorKey.currentState?.pushNamed('/settings'); // Redirect to the settings page
          } else if (payloadData['data']['navigateTo'] == 'settings') {
            navigatorKey.currentState?.pushNamed('/settings'); // Redirect to the settings page
          } else if (payloadData['navigateTo'] == 'watching_detail') {
            log(payloadData['watchingUid']);
            // navigatorKey.currentState?.pushNamed('/watching_detail'); // Redirect to the watching detail page
          }
        } catch (e) {
          log('Error decoding payload: $e');
        }
      } else {
        log('No payload received');
      }
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    log(auth.FirebaseAuth.instance.currentUser?.uid ?? 'No user logged in');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)), // Set textScaleFactor to 1
            child: MaterialApp(
              routes: {
                '/settings': (context) => const SettingsPage(), // Add the settings page route
                '/profile': (context) => const ProfilePage(), // Add the settings page route
              },
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Sabaidee',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: auth.FirebaseAuth.instance.currentUser == null
                  ? const SignInPage() // Default to Sign In page if not logged in
                  : FutureBuilder(
                      future: Provider.of<UserProvider>(context, listen: false)
                          .fetchUserData(auth.FirebaseAuth.instance.currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator()); // Show a loading indicator while fetching data
                        } else if (snapshot.hasError) {
                          log('Error fetching user data: ${snapshot.error}');
                          return const SignInPage(); // Redirect to Sign In page if there's an error
                        } else {
                          return const HomePage(); // Navigate to HomePage after fetching user data
                        }
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}