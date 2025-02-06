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
          final formattedStartTime = DateFormat('HH:mm').format(checkInTime.dateTime); // Format the time
          final formattedEndTime = DateFormat('HH:mm').format(checkInTime.dateTime.add(const Duration(minutes: 15))); // Format the time
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
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    child: ListTile(
      title: Container(
        padding: const EdgeInsets.all(8.0),
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
            Text('$formattedStartTime to $formattedEndTime'),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: () async{
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
          floatingActionButton: scheduleTimes.length < 4
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddScheduleTimePage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}