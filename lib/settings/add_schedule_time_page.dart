import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class AddScheduleTimePage extends StatefulWidget {
  const AddScheduleTimePage({super.key});

  @override
  _AddScheduleTimePageState createState() => _AddScheduleTimePageState();
}

class _AddScheduleTimePageState extends State<AddScheduleTimePage> {
  final List<int> _selectedHours = [];

  void _toggleHour(int hour) {
    setState(() {
      if (_selectedHours.contains(hour)) {
        _selectedHours.remove(hour);
      } else {
        if (_selectedHours.length < 4) {
          _selectedHours.add(hour);
        }
      }
    });
  }

  Future<void> _submitSchedule() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final now = DateTime.now();
    for (int hour in _selectedHours) {
      final dateTime = DateTime(now.year, now.month, now.day, hour, 0);
      await userProvider.addCheckInTime(dateTime);
    }
    print('Schedule times added: $_selectedHours');
    Navigator.of(context).pop();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Schedule Time', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.yellow,
      body: Column(
        children: [
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
                final formattedHour = DateFormat('hh:mm a').format(adjustedTime);
                final isSelected = _selectedHours.contains(hour);
                final isPending = pendingHours.contains(hour);

                return ElevatedButton(
                  onPressed: isPending ? null : () {
                    _toggleHour(hour);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.blue : null,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(100)) // Rounded shape
                    ),
                  ),
                  child: Text(formattedHour),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // Extend the button to the size of the screen
              child: ElevatedButton(
                onPressed: _submitSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Button color black
                ),
                child: const Text(
                  'SUBMIT',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Text color white
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}