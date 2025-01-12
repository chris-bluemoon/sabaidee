import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/screens/background_widget.dart';
import 'package:sabaidee/user_provider.dart';

class NextCheckInPage extends StatelessWidget {
  const NextCheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: Padding(
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9, // 90% of the screen width
                      height: MediaQuery.of(context).size.height * 0.3, // 30% of the screen height
                      padding: const EdgeInsets.all(16.0),
                      
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                        color: const Color(0xFFE8F0EB), // Light shade of the primary color
                        borderRadius: BorderRadius.circular(10),
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
                                nextCheckInTime.format(context),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Provider.of<UserProvider>(context, listen: false).addCheckInTime(nextCheckInTime);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checked in successfully')),
                        );
                      },
                      icon: const Icon(Icons.check_box_outlined),
                      label: const Text('Check In'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Handle "Hello LK" button press
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('I Need Help!')),
                        );
                      },
                      icon: const Icon(Icons.help_outline),
                      label: const Text('I Need Help'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDF6D2D), // Set the button color to #DF6D2D
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}