import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

import 'add_schedule_time_page.dart';

class MySchedulePage extends StatelessWidget {
  const MySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final scheduleTimes = userProvider.scheduleTimes;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('My Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.yellow,
      ),
      body: ListView.builder(
        itemCount: scheduleTimes.length,
        itemBuilder: (context, index) {
          final checkInTime = scheduleTimes[index];
          return Dismissible(
            key: Key(checkInTime.time.toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              await userProvider.deleteCheckInTime(checkInTime.time);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${checkInTime.time.format(context)}')),
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(checkInTime.time.format(context)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddScheduleTimePage()));
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}