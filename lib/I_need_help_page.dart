import 'dart:developer';

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
      appBar: AppBar(
        title: const Text(
          'EMERGENCY CONTACTS',
          style: TextStyle(fontWeight: FontWeight.bold), // Make the text bold
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.yellow, // Set the same background color as other pages
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
      backgroundColor: Colors.yellow, // Set the same background color as other pages
      body: Column(
        children: [
          const Spacer(), // Add a Spacer to push the GridView down
          Padding(
            padding: const EdgeInsets.all(16.0),
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
          const Spacer(), // Add another Spacer to balance the GridView in the middle
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String title;

  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userCountry = userProvider.user?.country['name'] ?? 'Test Country'; // Replace this with the actual method to get the user's country
    final emergencyHelplines = getEmergencyHelplines();
    final helpline = emergencyHelplines.firstWhere((helpline) => helpline.country == userCountry);

    String phoneNumber;
    switch (title) {
      case 'POLICE':
        phoneNumber = helpline.policeNumber;
        break;
      case 'FIRE BRIGADE':
        phoneNumber = helpline.fireBrigadeNumber;
        break;
      case 'AMBULANCE':
        phoneNumber = helpline.ambulanceNumber;
        break;
      default:
        phoneNumber = '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold), // Make the text bold
        ),
        centerTitle: true, // Center the title
        backgroundColor: Colors.yellow, // Set the same background color as other pages
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: MediaQuery.of(context).size.width * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.yellow,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal margin
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = 'tel:$phoneNumber';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    log('About to launch $url with phone number $phoneNumber');
                    await launchUrl(Uri.parse(url));
                  } else {
                    log('Could not launch $url');
                    throw 'Could not launch $url';
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
          ],
        ),
      ),
    );
  }
}