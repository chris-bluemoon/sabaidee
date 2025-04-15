import 'package:flutter/material.dart';

class WellnessDashboardPage extends StatelessWidget {
  const WellnessDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Check-In Summary
            Card(
              child: ListTile(
                leading: Icon(Icons.mood, size: screenWidth * 0.1),
                title: const Text('Today\'s Check-In'),
                subtitle: const Text('Mood: Happy\nEnergy: High'),
              ),
            ),
            const SizedBox(height: 16),

            // Progress Tracker
            const Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Progress Tracker'),
                    subtitle: Text('Mood trends over the past week'),
                  ),
                  SizedBox(
                    height: 200,
                    child: Placeholder(), // Replace with a graph widget
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Personalized Recommendations
            Card(
              child: ListTile(
                leading: Icon(Icons.lightbulb, size: screenWidth * 0.1),
                title: const Text('Recommendation'),
                subtitle: const Text('Take a 10-minute walk to boost your mood!'),
              ),
            ),
            const SizedBox(height: 16),

            // Achievements and Milestones
            Card(
              child: ListTile(
                leading: Icon(Icons.star, size: screenWidth * 0.1),
                title: const Text('Achievements'),
                subtitle: const Text('You\'ve completed 10 consecutive check-ins!'),
              ),
            ),
            const SizedBox(height: 16),

            // Weather and Location Insights
            Card(
              child: ListTile(
                leading: Icon(Icons.cloud, size: screenWidth * 0.1),
                title: const Text('Weather'),
                subtitle: const Text('Sunny, 25°C\nPerfect for outdoor activities!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}