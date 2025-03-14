import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final checkInTimes = userProvider.user?.checkInTimes ?? [];

    // Filter out pending or open check-in times
    final filteredCheckInTimes = checkInTimes.where((checkIn) => checkIn.status != 'pending' && checkIn.status != 'open').toList();

    // Map to translate status values
    final statusTranslations = {
      'missed': 'Missed a Check In',
      'checked in': 'Checked In',
      'pending': 'Pending',
    };

    // Map to associate status with icons and colors
    final statusIcons = {
      'missed': {'icon': Icons.error_outline, 'color': Colors.red},
      'checked in': {'icon': Icons.check_circle_outline, 'color': Colors.green},
      'pending': {'icon': Icons.hourglass_empty, 'color': Colors.blue}, // Change color to blue
    };

    return Scaffold(
      // backgroundColor: Colors.yellow,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: filteredCheckInTimes.isEmpty
                  ? Center(
                      child: Text(
                        'No history of activity yet',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCheckInTimes.length,
                      itemBuilder: (context, index) {
                        final checkIn = filteredCheckInTimes[index];
                        final formattedDate = DateFormat('MMM d, yyyy').format(checkIn.dateTime); // Format the date
                        final formattedTime = DateFormat('h:mm a').format(checkIn.dateTime); // Format the time with AM/PM without leading zero
                        final translatedStatus = statusTranslations[checkIn.status] ?? checkIn.status; // Translate the status
                        final statusIcon = statusIcons[checkIn.status]?['icon'] ?? Icons.help_outline; // Get the icon for the status
                        final statusColor = statusIcons[checkIn.status]?['color'] ?? Colors.black; // Get the color for the status

                        return Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02), // Add padding between containers
                          child: GlassmorphismContainer(
                            child: ListTile(
                              leading: Icon(statusIcon as IconData?, color: statusColor as Color?, size: 40), // Set the icon and color
                              title: Text(
                                translatedStatus,
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.045, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.black), // Calendar icon
                                  const SizedBox(width: 4.0),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                                  ),
                                  const SizedBox(width: 16.0), // Increase the width of the SizedBox for more spacing
                                  const Icon(Icons.access_time, size: 16, color: Colors.black), // Clock icon
                                  const SizedBox(width: 4.0),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double? height;

  const GlassmorphismContainer({required this.child, this.height, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height, // Set a consistent height for each box
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Semi-transparent white
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Semi-transparent white border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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