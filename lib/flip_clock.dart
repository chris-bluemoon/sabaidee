import 'package:flutter/material.dart';

class FlipClock extends StatefulWidget {
  const FlipClock({required this.time, super.key});

  final TimeOfDay time;

  @override
  _FlipClockState createState() => _FlipClockState();
}

class _FlipClockState extends State<FlipClock> {
  // late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   setState(() {
    //     _currentTime = DateTime.now();
    //   });
    // });
  }

  @override
  void dispose() {
    // _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeCard(widget.time.hour.toString().padLeft(2, '0')),
        const Text(':', style: TextStyle(fontSize: 50)),
        _buildTimeCard(widget.time.minute.toString().padLeft(2, '0')),
        // const Text(':', style: TextStyle(fontSize: 50)),
        // _buildTimeCard(_currentTime.second.toString().padLeft(2, '0')),
      ],
    );
  }

  Widget _buildTimeCard(String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: const TextStyle(
          fontSize: 50,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}