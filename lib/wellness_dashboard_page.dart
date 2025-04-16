import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sabaidee/chatbot_page.dart';

class WellnessDashboardPage extends StatelessWidget {
  const WellnessDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Wellness Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/images/bg2.png', // Background image
              fit: BoxFit.cover,
            ),
          ),
          // Glassmorphic content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100), // Space below the AppBar
                // Today's Check-In Section
                GlassmorphismContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Check-In",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "How are you feeling today?",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to check-in page or handle action
                        },
                        child: const Text('Start Check-In'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Chatbot Section
                GlassmorphismContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Chat with Wellness Assistant",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Need someone to talk to? Start a conversation with our assistant.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatbotPage(),
                            ),
                          );
                        },
                        child: const Text('CHAT NOW'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Recommendations Section
                const GlassmorphismContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Recommendations",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Here are some tips to improve your wellness today.",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "- Take a 10-minute walk.\n- Drink more water.\n- Practice mindfulness for 5 minutes.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Achievements Section
                const GlassmorphismContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Achievements",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Your recent accomplishments:",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "- Completed 5 check-ins this week.\n- Walked 10,000 steps yesterday.\n- Practiced mindfulness for 3 days in a row.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Weather Forecast Section
                const GlassmorphismContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Weather Forecast",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Today's weather:",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.wb_sunny, color: Colors.orange, size: 32),
                          SizedBox(width: 8),
                          Text(
                            "Sunny, 25°C",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
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

// Glassmorphism container widget
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;

  const GlassmorphismContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Make the container stretch the full width of the screen
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0), // Add spacing between sections
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.2), // Semi-transparent white
          border: Border.all(color: Colors.white.withOpacity(0.3)), // Border with transparency
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16), // Clip the child to match the border radius
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Apply blur effect
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Add padding inside the container
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}