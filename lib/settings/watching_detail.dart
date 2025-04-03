import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WatchingDetail extends StatelessWidget {
  final String watchingUid;
  final String createdAt;

  const WatchingDetail({
    required this.watchingUid,
    required this.createdAt,
    super.key,
  });

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Watching Details'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg3.png',
              fit: BoxFit.cover,
            ),
          ),
          // Glassmorphism effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          // Fetch and display details
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchWatchingDetails(watchingUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading details.'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('No details found.'));
              }

              final data = snapshot.data!;
              final watchingName = data['name'] ?? 'Unknown';
              final email = data['email'] ?? 'No email provided';
              final address = data['address'] ?? 'No address provided';
              final phoneNumber = data['phoneNumber'] ?? 'No phone number provided';
              final country = data['country']?['country'] ?? 'No country provided';
              final checkInTimes = data['checkInTimes'] as List<dynamic>? ?? [];

              return Center(
                child: GlassmorphismContainer(
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.6,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        Text(
                          'Name: $watchingName',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Email Field
                        Text(
                          'Email: $email',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Address Field
                        Text(
                          'Address: $address',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Phone Number Field
                        Text(
                          'Phone Number: $phoneNumber',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Country Field
                        Text(
                          'Country: $country',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Following Since Field
                        Text(
                          'Following Since: $createdAt',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        // Check-In Times Field
                        Text(
                          'Check-In Times:',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ...checkInTimes.map((checkIn) {
                          final dateTime = checkIn['dateTime'] ?? 'Unknown';
                          final status = checkIn['status'] ?? 'Unknown';
                          return Padding(
                            padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                            child: Text(
                              '- $dateTime: $status',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
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