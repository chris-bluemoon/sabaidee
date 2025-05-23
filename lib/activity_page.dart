import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:provider/provider.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Map the user's timezone offset to a valid timezone location name
    final timezoneMapping = {
      'UTC+00:00': 'UTC',
      'UTC+01:00': 'Europe/London',
      'UTC+02:00': 'Europe/Berlin',
      'UTC+03:00': 'Europe/Moscow',
      'UTC+04:00': 'Asia/Dubai',
      'UTC+05:00': 'Asia/Karachi',
      'UTC+06:00': 'Asia/Dhaka',
      'UTC+07:00': 'Asia/Bangkok',
      'UTC+08:00': 'Asia/Singapore',
      'UTC+09:00': 'Asia/Tokyo',
      'UTC+10:00': 'Australia/Sydney',
      'UTC+11:00': 'Pacific/Noumea',
      'UTC+12:00': 'Pacific/Auckland',
      'UTC-01:00': 'Atlantic/Azores',
      'UTC-02:00': 'America/Noronha',
      'UTC-03:00': 'America/Argentina/Buenos_Aires',
      'UTC-04:00': 'America/Halifax',
      'UTC-05:00': 'America/New_York',
      'UTC-06:00': 'America/Chicago',
      'UTC-07:00': 'America/Denver',
      'UTC-08:00': 'America/Los_Angeles',
      'UTC-09:00': 'America/Anchorage',
      'UTC-10:00': 'Pacific/Honolulu',
      'UTC-11:00': 'Pacific/Midway',
      'UTC-12:00': 'Etc/GMT+12',
    };

    final userTimezone = userProvider.user?.country['timezone'] ?? 'UTC';
    final locationName = timezoneMapping[userTimezone] ?? 'UTC';
    final location = tz.getLocation(locationName);

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
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCheckInTimes.length,
                      itemBuilder: (context, index) {
                        final checkIn = filteredCheckInTimes[index];
                        final localDateTime = tz.TZDateTime.from(checkIn.dateTime, location);
                        final formattedDate = DateFormat('MMM d, yyyy').format(localDateTime); // Format the date
                        final formattedTime = DateFormat('h:mm a').format(localDateTime); // Format the time with AM/PM without leading zero
                        final translatedStatus = statusTranslations[checkIn.status] ?? checkIn.status; // Translate the status
                        final statusIcon = statusIcons[checkIn.status]?['icon'] ?? Icons.help_outline; // Get the icon for the status
                        final statusColor = statusIcons[checkIn.status]?['color'] ?? Colors.black; // Get the color for the status

                        return Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.02), // Add padding between containers
                          child: GlassmorphismContainer(
                            child: ListTile(
                              leading: Icon(
                                statusIcon as IconData?,
                                color: statusColor as Color?,
                                size: screenWidth * 0.1, // Set the icon size relative to the screen width
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    translatedStatus,
                                    style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                                  ),
                                  if (checkIn.emoji != null) // Check if emoji is not null
                                    Padding(
                                      padding: EdgeInsets.only(left: screenWidth * 0.08), // Increase spacing between status and emoji
                                      child: Text(
                                        checkIn.emoji!,
                                        style: TextStyle(fontSize: screenWidth * 0.05), // Set emoji font size
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: screenWidth * 0.04, color: Colors.black), // Calendar icon
                                      SizedBox(width: screenWidth * 0.01),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(fontSize: screenWidth * 0.04),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenWidth * 0.01), // Add spacing between rows
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: screenWidth * 0.04, color: Colors.black), // Clock icon
                                      SizedBox(width: screenWidth * 0.01),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(fontSize: screenWidth * 0.04),
                                      ),
                                    ],
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