import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class NextCheckInPage extends StatelessWidget {
  const NextCheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow, // Set background color to yellow
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final checkInTimes = userProvider.user?.checkInTimes.where((time) => time.status == 'pending').toList();

            if (userProvider.user?.checkInTimes.isEmpty ?? true) {
              return const Center(
                child: Text('No Check In Times Set Up Yet'),
              );
            }

            if (checkInTimes == null || checkInTimes.isEmpty) {
              return const Center(
                child: Text('No check-in times available'),
              );
            } 

            // Find the next check-in time
            final now = TimeOfDay.now();
            final futureCheckInTimes = checkInTimes
                .where((checkInTime) => checkInTime.dateTime.hour > now.hour || (checkInTime.dateTime.hour == now.hour && checkInTime.dateTime.minute > now.minute))
                .toList();

            CheckInTime nextCheckInTime;
            if (futureCheckInTimes.isNotEmpty) {
              nextCheckInTime = futureCheckInTimes.reduce((a, b) => a.dateTime.hour < b.dateTime.hour || (a.dateTime.hour == b.dateTime.hour && a.dateTime.minute < b.dateTime.minute) ? a : b);
            } else {
              nextCheckInTime = checkInTimes.reduce((a, b) => a.dateTime.hour < b.dateTime.hour || (a.dateTime.hour == b.dateTime.hour && a.dateTime.minute < b.dateTime.minute) ? a : b);
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 150),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9, // 90% of the screen width
                    height: MediaQuery.of(context).size.height * 0.4, // 30% of the screen height
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0EB), // Light shade of the primary color
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Next Check-In Time',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${nextCheckInTime.dateTime.hour.toString().padLeft(2, '0')}:${nextCheckInTime.dateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      // FlipClock(time: nextCheckInTime),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Provider.of<UserProvider>(context, listen: false).addCheckInTime(nextCheckInTime);
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
                      userProvider.setCheckInStatus(TimeOfDay(hour: nextCheckInTime.dateTime.hour, minute: nextCheckInTime.dateTime.minute), 'checked in');
                    },
                    icon: const Icon(Icons.check_box_outlined),
                    label: const Text('CHECK IN'),
                                    style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Button color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('I Need Help!')),
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
    );
  }
}