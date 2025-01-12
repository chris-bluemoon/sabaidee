import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class AddSchedulePage extends StatefulWidget {
  const AddSchedulePage({super.key});

  @override
  _AddSchedulePageState createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  TimeOfDay? _selectedTime;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addCheckInTime() async {
    if (_selectedTime != null) {
      Provider.of<UserProvider>(context, listen: false).addCheckInTime(_selectedTime!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check In time added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Schedule')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectTime(context),
              child: const Text('Select Time'),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedTime != null ? _selectedTime!.format(context) : 'No time selected',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCheckInTime,
              child: const Text('Add Schedule Time'),
            ),
          ],
        ),
      ),
    );
  }
}