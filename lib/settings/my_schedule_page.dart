import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'add_schedule_time_page.dart';

class MySchedulePage extends StatelessWidget {
  const MySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final pendiningOrOpenScheduleTimes = userProvider.pendingOrOpenCheckInTimes;
    final screenWidth = MediaQuery.of(context).size.width;
    final userTimezone = userProvider.user?.country['timezone'] ?? 'UTC';

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

    final locationName = timezoneMapping[userTimezone] ?? 'UTC';
    final location = tz.getLocation(locationName);

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text(
          'MY SCHEDULE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow,
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0), // Decrease the padding slightly
            child: Text(
              'Set up to 4 check-ins per day. You can change the amount of time to check in under settings, the default is 15 minutes. Changes to the current schedule are effective the next day.',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pendiningOrOpenScheduleTimes.length,
              itemBuilder: (context, index) {
                final checkInTime = pendiningOrOpenScheduleTimes[index];
                log('checkInTime: ${checkInTime.dateTime}');
                // final localStartTime = tz.TZDateTime.from(checkInTime.dateTime, location);
                // final utcTime = tz.TZDateTime.utc(checkInTime.dateTime.year, checkInTime.dateTime.month, checkInTime.dateTime.day, checkInTime.dateTime.hour);
                final localStartTime = tz.TZDateTime.from(checkInTime.dateTime, location);
                log('localStartTime: $localStartTime');
                final localEndTime = localStartTime.add(checkInTime.duration);
                final formattedStartTime = DateFormat('hh:mm a').format(localStartTime); // Format the time to 12-hour with AM/PM
                final formattedEndTime = DateFormat('hh:mm a').format(localEndTime); // Format the time to 12-hour with AM/PM
                return Dismissible(
                  key: Key(checkInTime.dateTime.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    await userProvider.deleteCheckInTime(checkInTime);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Container(
                      padding: const EdgeInsets.fromLTRB(12.0, 6.0, 6.0, 6.0), // Increase the left padding slightly
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: '$formattedStartTime to $formattedEndTime',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.06, // Set the font size relative to the screen width
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.black, size: screenWidth * 0.08), // Set the icon size relative to the screen width  
                            onPressed: () async {
                              // Handle delete action
                              await userProvider.deleteCheckInTime(checkInTime);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: pendiningOrOpenScheduleTimes.length < 4
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddScheduleTimePage(),
                  ),
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}