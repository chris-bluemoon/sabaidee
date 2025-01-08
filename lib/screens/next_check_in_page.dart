import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class NextCheckInPage extends StatelessWidget {
  const NextCheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Next Check-In Time')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final checkInTimes = userProvider.checkInTimes;
            if (checkInTimes == null || checkInTimes.isEmpty) {
              return const Center(
                child: Text('No check-in times available'),
              );
            }

            // Find the next check-in time
            final now = TimeOfDay.now();
            final futureCheckInTimes = checkInTimes
                .where((time) => time.hour > now.hour || (time.hour == now.hour && time.minute > now.minute))
                .toList();

            TimeOfDay nextCheckInTime;
            if (futureCheckInTimes.isNotEmpty) {
              nextCheckInTime = futureCheckInTimes.reduce((a, b) => a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute) ? a : b);
            } else {
              nextCheckInTime = checkInTimes.reduce((a, b) => a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute) ? a : b);
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Next Check-In Time',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          nextCheckInTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await Provider.of<UserProvider>(context, listen: false).addCheckInTime(nextCheckInTime);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checked in successfully')),
                      );
                    },
                    child: const Text('Check In'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle "I need help" button press
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help is on the way!')),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('I need help'),
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
