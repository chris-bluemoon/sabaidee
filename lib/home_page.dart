import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sabaidee/activity_page.dart';
import 'package:sabaidee/next_check_in_page.dart';
import 'package:sabaidee/settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  static const List<Widget> _pages = <Widget>[
    NextCheckInPage(),
    ActivityPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Extend the body behind the bottom navigation bar
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent, // Make the background transparent
        color: Colors.white, // Color of the navigation bar
        buttonBackgroundColor: Colors.white, // Color of the button background
        height: 60, // Height of the navigation bar
        items: <Widget>[
          Icon(Icons.home, size: 30, color: _selectedIndex == 0 ? Colors.black : Colors.grey),
          Icon(Icons.business, size: 30, color: _selectedIndex == 1 ? Colors.black : Colors.grey),
          Icon(Icons.settings, size: 30, color: _selectedIndex == 2 ? Colors.black : Colors.grey),
        ],
        index: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}