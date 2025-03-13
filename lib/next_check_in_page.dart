import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/I_need_help_page.dart';
import 'package:sabaidee/user_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NextCheckInPage extends StatefulWidget {
  const NextCheckInPage({super.key});

  @override
  State<NextCheckInPage> createState() => _NextCheckInPageState();
}

class _NextCheckInPageState extends State<NextCheckInPage> with WidgetsBindingObserver {
  late final String formattedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    formattedDate = DateFormat('E, d MMMM yyyy').format(now).toUpperCase(); // Format the date
    _fetchUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      await userProvider.fetchUserData(userProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.user == null) {
                  log('Building NEXT_CHECK_IN_PAGE but user is null');
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final checkInTimes = userProvider.user?.checkInTimes.where((time) => (time.status == 'pending' || time.status == 'open')).toList();
                if (userProvider.user?.checkInTimes.isEmpty ?? true) {
                  return const Center(
                    child: Text('No Check In Times Set Up Yet'),
                  );
                }

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

                // Find the next check-in time
                final now = DateTime.now().toUtc();
                final futureCheckInTimes = checkInTimes?.where((checkInTime) => checkInTime.dateTime.isAfter(now.subtract(Duration(minutes: checkInTime.duration.inMinutes)))).toList() ?? [];

                CheckInTime? nextOrOpenCheckInTime;
                if (futureCheckInTimes.isNotEmpty) {
                  nextOrOpenCheckInTime = futureCheckInTimes.reduce((a, b) => a.dateTime.isBefore(b.dateTime) ? a : b);
                  log('nextOrOpenCheckInTime: ${nextOrOpenCheckInTime.dateTime}');
                } else {
                  log('futureCheckInTimes is empty');
                }

                if (nextOrOpenCheckInTime == null) {
                  log('No upcoming check-in times');
                }

                final localStartTime = nextOrOpenCheckInTime != null ? tz.TZDateTime.from(nextOrOpenCheckInTime.dateTime, location) : null;
                final localEndTime = localStartTime != null && nextOrOpenCheckInTime != null ? localStartTime.add(nextOrOpenCheckInTime.duration) : null;
                final formattedStartTime = localStartTime != null ? DateFormat('h:mm a').format(localStartTime) : '';
                final formattedEndTime = localEndTime != null ? DateFormat('h:mm a').format(localEndTime) : '';
                log(nextOrOpenCheckInTime?.status ?? 'No check-in time set up');

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      Row(
                        children: [
                          Text(formattedDate, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 50),
                      nextOrOpenCheckInTime != null && nextOrOpenCheckInTime.status == 'open'
                          ? GlassmorphismContainer(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Check In Now',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        formattedStartTime,
                                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_downward_outlined , size: 40), 
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        formattedEndTime,
                                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20), // Add a SizedBox to increase the gap
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Checked in successfully')),
                                      );
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Check In Success!'),
                                            content: const Text('You have successfully checked in.'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('OK'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      // Set the status of the check-in time to "checked in"
                                      if (nextOrOpenCheckInTime != null) {
                                        userProvider.setCheckInStatus(nextOrOpenCheckInTime.dateTime, 'checked in');
                                        log('Check-in time status updated to "checked in"');
                                        // Calculate the new check-in time 24 hours in the future
                                        DateTime newCheckInTime = nextOrOpenCheckInTime.dateTime.add(const Duration(hours: 24));
                                        userProvider.addCheckInTime(newCheckInTime);
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('CHECK IN'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue, // Change button color to blue
                                      foregroundColor: Colors.white, // Text color
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30.0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GlassmorphismContainer(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Next Check In',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal),
                                  ),
                                  const SizedBox(height: 5),
                                  Expanded(
                                    child: Center(
                                      child: nextOrOpenCheckInTime != null
                                          ? Column(
                                            children: [
                                              Text(
                                                  formattedStartTime,
                                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              const Icon(Icons.arrow_downward_outlined , size: 40), 
                                              Text(
                                                  formattedEndTime,
                                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                            ],
                                          )
                                          : const Text(
                                              'No Check In Time Set Up',
                                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                    ),
                                  ),
                                  if (nextOrOpenCheckInTime != null && nextOrOpenCheckInTime.dateTime.day == DateTime.now().add(const Duration(days: 1)).day)
                                    const Text(
                                      '(tomorrow)',
                                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.normal),
                                    ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 60),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const INeedHelpPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_hospital),
                        label: const Text('I NEED HELP!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Button color
                          foregroundColor: Colors.white, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // More rounded corners
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
          width: MediaQuery.of(context).size.width * 0.9, // 90% of the screen width
          height: MediaQuery.of(context).size.height * 0.4, // 40% of the screen height
          padding: const EdgeInsets.all(16.0),
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