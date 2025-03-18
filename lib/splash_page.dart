import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sabaidee/main.dart'; // Import the main.dart file to access AuthWrapper

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()), // Navigate to the AuthWrapper
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png', // Replace with your splash background image
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Image.asset(
              'assets/images/logo.png', // Replace with your logo image
              width: 200,
              height: 200,
            ),
          ),
        ],
      ),
    );
  }
}