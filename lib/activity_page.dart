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
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('ACTIVITY', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: MediaQuery.of(context).size.width * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: checkInTimes.length,
          itemBuilder: (context, index) {
            final checkIn = checkInTimes[index];
            final formattedDate = DateFormat('MMM d, yyyy').format(checkIn.dateTime); // Format the date
            final formattedTime = DateFormat('h:mm a').format(checkIn.dateTime); // Format the time with AM/PM without leading zero
            final translatedStatus = statusTranslations[checkIn.status] ?? checkIn.status; // Translate the status
            final statusIcon = statusIcons[checkIn.status]?['icon'] ?? Icons.help_outline; // Get the icon for the status
            final statusColor = statusIcons[checkIn.status]?['color'] ?? Colors.black; // Get the color for the status

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
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
            );
          },
        ),
      ),
    );
  }
}