import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // Add this import at the top of the file
import 'package:url_launcher/url_launcher.dart';

class WatchingDetail extends StatelessWidget {
  final String watchingUid;

  const WatchingDetail({
    super.key,
    required this.watchingUid,
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

  Map<String, String> _getLastCheckInTime(List<dynamic>? checkInTimes) {
    if (checkInTimes == null || checkInTimes.isEmpty) {
      return {'time': 'Unknown', 'status': 'No Check-Ins', 'emoji': ''};
    }

    // Filter out entries with a status of 'pending'
    final filteredCheckInTimes = checkInTimes.where((entry) {
      return entry['status']?.toLowerCase() != 'pending';
    }).toList();

    if (filteredCheckInTimes.isEmpty) {
      return {'time': 'Unknown', 'status': 'No Valid Check-Ins', 'emoji': ''};
    }

    // Sort the filtered check-in times in ascending order
    filteredCheckInTimes.sort((a, b) {
      final aTime = DateTime.parse(a['dateTime']);
      final bTime = DateTime.parse(b['dateTime']);
      return aTime.compareTo(bTime);
    });

    // Get the last entry
    final lastCheckIn = filteredCheckInTimes.last;
    final lastCheckInTime = DateTime.parse(lastCheckIn['dateTime']);
    String status = lastCheckIn['status'] ?? 'Unknown'; // Get the status from the last check-in entry
    String emoji = lastCheckIn['emoji'] ?? ''; // Get the emoji from the last check-in entry

    // Capitalize the first letter of the status
    status = status.toLowerCase().replaceFirst(status[0], status[0].toUpperCase());

    // Format the last check-in time without a comma between the month and the year
    final formattedTime = DateFormat('EEE, d\'${_getDaySuffix(lastCheckInTime.day)}\' MMMM yyyy @ HH:mm')
        .format(lastCheckInTime);

    return {
      'time': formattedTime,
      'status': status,
      'emoji': emoji,
    };
  }

  // Helper function to get the day suffix (e.g., 'st', 'nd', 'rd', 'th')
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
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
                      height: 160, // Adjust height to accommodate new fields
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Address: ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                TextSpan(
                                  text: address,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Phone: ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                TextSpan(
                                  text: phoneNumber,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Status: ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                TextSpan(
                                  text: '${_getLastCheckInTime(watchingDetails['checkInTimes'])['status']}\u00A0\u00A0', // Add two non-breaking spaces
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
                                ),
                                TextSpan(
                                  text: _getLastCheckInTime(watchingDetails['checkInTimes'])['emoji'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'When: ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                TextSpan(
                                  text: _getLastCheckInTime(watchingDetails['checkInTimes'])['time'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
                                ),
                              ],
                            ),
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