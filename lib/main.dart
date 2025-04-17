import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/I_need_help_page.dart';
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

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate Firebase App Check
  // await FirebaseAppCheck.instance.activate(
    // androidProvider: AndroidProvider.debug,
  // );

  // final debugToken = await FirebaseAppCheck.instance.getToken(true);
  // log('Debug Token: $debugToken');

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
                '/settings': (context) => const SettingsPage(),
                '/profile': (context) => const ProfilePage(),
                '/i_need_help': (context) => const INeedHelpPage(),
              },
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Sabaidee',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              home: auth.FirebaseAuth.instance.currentUser == null
                  ? const SignInPage()
                  : FutureBuilder(
                      future: Provider.of<UserProvider>(context, listen: false)
                          .fetchUserData(auth.FirebaseAuth.instance.currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          log('Error fetching user data: ${snapshot.error}');
                          return const SignInPage();
                        } else {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                            child: const HomePage(),
                          );
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