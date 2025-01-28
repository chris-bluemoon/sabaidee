import 'package:flutter/material.dart';
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
    for (int hour in _selectedHours) {
      final time = TimeOfDay(hour: hour, minute: 0);
      await userProvider.addCheckInTime(time);
    }
    print('Schedule times added: $_selectedHours');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final pendingCheckInTimes = userProvider.pendingCheckInTimes;
    final pendingHours = pendingCheckInTimes.map((checkInTime) => checkInTime.dateTime).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Schedule Time'),
      ),
      backgroundColor: Colors.yellow,
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 columns
                childAspectRatio: 1, // Square buttons
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: 24, // 24 hours in a day
              itemBuilder: (context, index) {
                final hour = index;
                final isSelected = _selectedHours.contains(hour);
                final isPending = pendingHours.contains(hour);

                return ElevatedButton(
                  onPressed: isPending ? null : () {
                    _toggleHour(hour);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.blue : null,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Square shape
                    ),
                  ),
                  child: Text('$hour:00'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitSchedule,
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}