import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WatchingDetail extends StatelessWidget {
  final String watchingUid;

  const WatchingDetail({
    Key? key,
    required this.watchingUid,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _fetchWatchingDetails(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      debugPrint('Error fetching watching details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchWatchingDetails(watchingUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('No Details'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const Center(child: Text('No details available.')),
          );
        }

        final watchingDetails = snapshot.data!;
        final phoneNumber = watchingDetails['phoneNumber'] ?? 'Unknown';
        final address = watchingDetails['address'] ?? 'Unknown';
        final watchingName = watchingDetails['name'] ?? 'Unknown';

        return Scaffold(
          appBar: AppBar(
            title: Text(watchingName), // Set the AppBar title to the user's name
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          extendBodyBehindAppBar: true, // Extend the body behind the AppBar
          body: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg3.png', // Path to your bg3.png file
                  fit: BoxFit.cover,
                ),
              ),
              // Blur Effect
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Apply blur effect
                  child: Container(
                    color: Colors.black.withOpacity(0.2), // Add a semi-transparent overlay
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100), // Add spacing for the AppBar
                    GlassmorphismContainer(
                      width: double.infinity,
                      height: 120, // Adjust height as needed
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address: $address',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Phone: $phoneNumber',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (phoneNumber != 'Unknown') {
                                launchUrl(Uri.parse('tel:$phoneNumber'));
                              }
                            },
                            icon: const Icon(Icons.phone),
                            label: Text('CALL $watchingName'.toUpperCase()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (phoneNumber != 'Unknown') {
                                launchUrl(Uri.parse('https://wa.me/$phoneNumber'));
                              }
                            },
                            icon: const FaIcon(FontAwesomeIcons.whatsapp),
                            label: Text('WHATSAPP $watchingName'.toUpperCase()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const GlassmorphismContainer({
    required this.child,
    required this.width,
    required this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}