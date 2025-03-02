import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

import 'add_schedule_time_page.dart';

class MySchedulePage extends StatelessWidget {
  const MySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final pendiningOrOpenScheduleTimes = userProvider.pendingOrOpenCheckInTimes;
    final screenWidth = MediaQuery.of(context).size.width;

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
              'Set up to 4 check-ins per day. You can change the amount of time to check in under settings, the default is 30 minutes. Changes to the current schedule are effective the next day.',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pendiningOrOpenScheduleTimes.length,
              itemBuilder: (context, index) {
                final checkInTime = pendiningOrOpenScheduleTimes[index];
                final formattedStartTime = DateFormat('hh:mm a').format(checkInTime.dateTime); // Format the time to 12-hour with AM/PM
                final formattedEndTime = DateFormat('hh:mm a').format(checkInTime.dateTime.add(const Duration(minutes: 5))); // Format the time to 12-hour with AM/PM
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
                                fontSize: screenWidth * 0.05, // Set the font size relative to the screen width
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.black),
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