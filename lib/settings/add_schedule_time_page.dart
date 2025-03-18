import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:timezone/timezone.dart';

class AddScheduleTimePage extends StatefulWidget {
  const AddScheduleTimePage({super.key});

  @override
  _AddScheduleTimePageState createState() => _AddScheduleTimePageState();
}

class _AddScheduleTimePageState extends State<AddScheduleTimePage> {
  final List<int> _selectedHours = [];
  bool _isLoading = false;

  void _toggleHour(int hour, int totalSelectedHours) {
    setState(() {
      if (_selectedHours.contains(hour)) {
        _selectedHours.remove(hour);
      } else {
        if (totalSelectedHours < 4) {
          _selectedHours.add(hour);
        } else {
          final screenWidth = MediaQuery.of(context).size.width;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum number of check-in times reached. Please remove a time to add a new one.',
                style: TextStyle(fontSize: screenWidth * 0.04), // Adjust text size relative to screen width
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _submitSchedule() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final now = DateTime.now();
    final userTimezone = userProvider.user?.country['timezone'] ?? 'UTC';

    log('Users timezone is $userTimezone');
    // Calculate the offset in hours and minutes
    final sign = userTimezone[3] == '-' ? -1 : 1;
    final timezoneOffset = Duration(
      hours: sign * int.parse(userTimezone.substring(4, 6)),
      minutes: sign * int.parse(userTimezone.substring(7, 9)),
    );
    log('Timezone offset is $timezoneOffset');

    log(_selectedHours.toString());
    for (int hour in _selectedHours) {
      // Adjust the dateTime to the user's timezone for the next day
      log('Hour is set to $hour');
      final localDateTime = DateTime(now.year, now.month, now.day + 1, hour, 0).subtract(timezoneOffset);
      final utcDateTime = TZDateTime.utc(now.year, now.month, now.day + 1, hour, 0).subtract(timezoneOffset);
      log('localDateTime in users location is $localDateTime');
      log('utcDateTime in users location is $utcDateTime');
      await userProvider.addCheckInTime(utcDateTime);
    }
    print('Schedule times added: $_selectedHours');

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final pendingCheckInTimes = userProvider.pendingOrOpenCheckInTimes;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final userTimezone = userProvider.user?.country['timezone'] ?? 'UTC';

    // Calculate the offset in hours and minutes
    final sign = userTimezone[3] == '-' ? -1 : 1;
    final timezoneOffset = Duration(
      hours: sign * int.parse(userTimezone.substring(4, 6)),
      minutes: sign * int.parse(userTimezone.substring(7, 9)),
    );

    // Adjust pending check-in times to the user's timezone
    final pendingHours = pendingCheckInTimes.map((checkInTime) {
      final adjustedTime = checkInTime.dateTime.toUtc().add(timezoneOffset);
      return adjustedTime.hour;
    }).toSet();

    final totalSelectedHours = _selectedHours.length + pendingHours.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Add Schedule Time', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.pop(context); // Go back to the settings page
          },
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg3.png',
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
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.08), // Add space below the app bar
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 columns
                      childAspectRatio: screenWidth / (screenHeight / 4), // Adjust the aspect ratio to fit the text
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: 24, // 24 hours in a day
                    itemBuilder: (context, index) {
                      final adjustedTime = DateTime(0, 1, 1, index).toUtc().add(timezoneOffset);
                      final hour = adjustedTime.hour;
                      final formattedHour = DateFormat('h:mm a').format(adjustedTime); // Use 'h' instead of 'hh' to remove leading zero
                      final isSelected = _selectedHours.contains(hour);
                      final isPending = pendingHours.contains(hour);

                      return ElevatedButton(
                        onPressed: isPending ? null : () {
                          _toggleHour(hour, totalSelectedHours);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.blue : null,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(100)) // Rounded shape
                          ),
                          padding: EdgeInsets.zero, // Reduce padding within the button
                        ),
                        child: Text(
                          formattedHour,
                          style: TextStyle(
                            color: isPending ? Colors.black : (isSelected ? Colors.white : Colors.black), // Change text color based on selection and pending status
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Make selected text darker
                            fontSize: screenWidth * 0.04, // Ensure consistent text size
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedHours.isNotEmpty) // Only show the SUBMIT button if a time is selected
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity, // Extend the button to the size of the screen
                      child: ElevatedButton(
                        onPressed: _submitSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Set the background color to black
                          foregroundColor: Colors.white, // Set the text color to white
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20), // Match the border radius of the GlassmorphismContainer
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0), // Add padding for a consistent look
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('SUBMIT', style: TextStyle(fontSize: screenWidth * 0.045)),
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

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double height;

  const GlassmorphismContainer({required this.child, required this.height, super.key});

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