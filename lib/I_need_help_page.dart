import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'user_provider.dart';
import 'utils/emergency_helplines.dart';

class INeedHelpPage extends StatelessWidget {
  const INeedHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'EMERGENCY CONTACTS',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make the text bold
            fontSize: screenWidth * 0.05, // Set the size relative to the screen width
          ),
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.transparent, // Transparent background
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg1.png',
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
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Remove top padding
              child: GridView.builder(
                shrinkWrap: true, // Make the GridView take only the necessary space
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  childAspectRatio: 1, // 1:1 aspect ratio for square tiles
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final titles = ["POLICE", "FIRE BRIGADE", "AMBULANCE", "HOSPITALS"];
                  final icons = [Icons.local_police, Icons.local_fire_department, Icons.local_hospital, Icons.local_hospital];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DetailPage(title: titles[index].toUpperCase()),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue, // Set the background color to blue
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            titles[index],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Change text color to white
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;

  const GlassmorphismContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Remove top padding
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Semi-transparent white
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Semi-transparent white border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String title;

  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final userProvider = Provider.of<UserProvider>(context);
    final userCountry = userProvider.user?.country['DUMMY-TODO'] ?? 'Test Country'; // Replace this with the actual method to get the user's country
    final emergencyHelplines = getEmergencyHelplines();
    final helpline = emergencyHelplines.firstWhere((helpline) => helpline.country == userCountry);
    log(helpline.policeNumber);

    String phoneNumber;
    String mapQuery;
    switch (title) {
      case 'POLICE':
        phoneNumber = helpline.policeNumber;
        mapQuery = 'police station near me';
        break;
      case 'FIRE BRIGADE':
        phoneNumber = helpline.fireBrigadeNumber;
        mapQuery = 'fire station near me';
        break;
      case 'AMBULANCE':
        phoneNumber = helpline.ambulanceNumber;
        mapQuery = 'hospital near me';
        break;
      default:
        phoneNumber = '';
        mapQuery = 'emergency services near me';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make the text bold
            fontSize: screenWidth * 0.05, // Set the size relative to the screen width
          ),
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.transparent, // Transparent background
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg1.png',
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
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal margin
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final url = 'tel:$phoneNumber';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          log('About to launch $url with phone number $phoneNumber');
                          await launchUrl(Uri.parse(url));
                        } else {
                          throw 'Could not launch $url';
                        }
                      } catch (e) {
                        log(e.toString());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 8.0), // Add space between icon and text
                      child: Icon(Icons.phone, color: Colors.white),
                    ),
                    label: Text(
                      'CALL THE $title EMERGENCY HELPLINE',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Button background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0), // Rounded edges
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Add space between buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal margin
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final encodedQuery = Uri.encodeComponent(mapQuery);
                        final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
                        final appleMapsUrl = 'https://maps.apple.com/?q=$encodedQuery';

                        if (await canLaunchUrl(Uri.parse('comgooglemaps://'))) {
                          // Launch Google Maps if available
                          await launchUrl(Uri.parse('comgooglemaps://?q=$encodedQuery'));
                        } else if (await canLaunchUrl(Uri.parse('maps://'))) {
                          // Launch Apple Maps if available
                          await launchUrl(Uri.parse(appleMapsUrl));
                        } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                          // Launch Google Maps in browser
                          await launchUrl(Uri.parse(googleMapsUrl));
                        } else {
                          throw 'Could not launch maps';
                        }
                      } catch (e) {
                        log(e.toString());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 8.0), // Add space between icon and text
                      child: Icon(Icons.map, color: Colors.white),
                    ),
                    label: Text(
                      'FIND NEAREST $title',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Button background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0), // Rounded edges
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}