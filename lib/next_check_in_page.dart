import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/models/check_in_time.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NextCheckInPage extends StatefulWidget {
  const NextCheckInPage({super.key});

  @override
  State<NextCheckInPage> createState() => _NextCheckInPageState();
}

class _NextCheckInPageState extends State<NextCheckInPage> with WidgetsBindingObserver {
  late final String formattedDate;
  bool _isLoading = true;
  String? _weatherIconUrl; // URL for the weather icon
  String? _placeName; // Name of the place
  String? _weatherType; // Add this variable to store the weather type

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    formattedDate = DateFormat('E, d MMMM yyyy').format(now).toUpperCase(); // Format the date
    _fetchUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    print('Fetching weather data...1');
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      await userProvider.fetchUserData(userProvider.user!.uid);

      // Fetch weather data if location sharing is enabled
      if (userProvider.user!.locationSharingEnabled) {
        print('Fetching weather data...');
        await _fetchWeatherData();
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchWeatherData() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Permission.locationWhenInUse.serviceStatus.isEnabled;
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Get the current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latitude = position.latitude;
      final longitude = position.longitude;

      print('\x1B[31mLatitude: $latitude\x1B[0m');   // Red text
      print('\x1B[31mLongitude: $longitude\x1B[0m'); // Red text

      // Fetch weather data from OpenWeatherMap API
      const weatherApiKey = '78cf2627afb3a056ab5593814b9a5238';
      final weatherUrl = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=metric');
      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode == 200) {
        final weatherData = jsonDecode(weatherResponse.body);
        final iconCode = weatherData['weather'][0]['icon'];
        final weatherType = weatherData['weather'][0]['description']; // Extract weather type
        setState(() {
          _weatherIconUrl = 'https://openweathermap.org/img/wn/$iconCode@2x.png';
          _weatherType = weatherType; // Store the weather type
        });
      } else {
        throw Exception('Failed to fetch weather data: ${weatherResponse.statusCode}');
      }

      final geocodingUrl = Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=metric');
          // 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$geocodingApiKey');
      final geocodingResponse = await http.get(geocodingUrl);

      if (geocodingResponse.statusCode == 200) {
        final geocodingData = jsonDecode(geocodingResponse.body);
        final results = geocodingData['name'];
        if (results != null && results.isNotEmpty) {
          setState(() {
            _placeName = results;
          });
        } else {
          print(geocodingData.toString());
          print(geocodingData['name']);
          setState(() {
            _placeName = 'Unknown location';
          });
        }
      } else {
        throw Exception('Failed to fetch place name: ${geocodingResponse.statusCode}');
      }
    } catch (e) {
      print('\x1B[31mError: $e\x1B[0m'); // Red text
      setState(() {
        _placeName = 'Error fetching location';
        _weatherType = null; // Reset weather type on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg1.png',
              fit: BoxFit.cover,
            ),
          ),
          // Glassmorphism effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          // Main content
          RefreshIndicator(
            onRefresh: _fetchUserData,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final checkInTimes = userProvider.user?.checkInTimes.where((time) => (time.status == 'pending' || time.status == 'open')).toList();

                  // Initialize timezone data
                  tz.initializeTimeZones();

                  // Map the user's timezone offset to a valid timezone location name
                  final timezoneMapping = {
                    'UTC+00:00': 'UTC',
                    'UTC+01:00': 'Europe/London',
                    'UTC+02:00': 'Europe/Berlin',
                    'UTC+03:00': 'Europe/Moscow',
                    'UTC+04:00': 'Asia/Dubai',
                    'UTC+05:00': 'Asia/Karachi',
                    'UTC+06:00': 'Asia/Dhaka',
                    'UTC+07:00': 'Asia/Bangkok',
                    'UTC+08:00': 'Asia/Singapore',
                    'UTC+09:00': 'Asia/Tokyo',
                    'UTC+10:00': 'Australia/Sydney',
                    'UTC+11:00': 'Pacific/Noumea',
                    'UTC+12:00': 'Pacific/Auckland',
                    'UTC-01:00': 'Atlantic/Azores',
                    'UTC-02:00': 'America/Noronha',
                    'UTC-03:00': 'America/Argentina/Buenos_Aires',
                    'UTC-04:00': 'America/Halifax',
                    'UTC-05:00': 'America/New_York',
                    'UTC-06:00': 'America/Chicago',
                    'UTC-07:00': 'America/Denver',
                    'UTC-08:00': 'America/Los_Angeles',
                    'UTC-09:00': 'America/Anchorage',
                    'UTC-10:00': 'Pacific/Honolulu',
                    'UTC-11:00': 'Pacific/Midway',
                    'UTC-12:00': 'Etc/GMT+12',
                  };

                  final userTimezone = userProvider.user?.country['timezone'] ?? 'UTC';
                  final locationName = timezoneMapping[userTimezone] ?? 'UTC';
                  final location = tz.getLocation(locationName);

                  // Find the next check-in time
                  final now = DateTime.now().toUtc();
                  final futureCheckInTimes = checkInTimes?.where((checkInTime) => checkInTime.dateTime.isAfter(now.subtract(Duration(minutes: checkInTime.duration.inMinutes)))).toList() ?? [];

                  CheckInTime? nextOrOpenCheckInTime;
                  if (futureCheckInTimes.isNotEmpty) {
                    nextOrOpenCheckInTime = futureCheckInTimes.reduce((a, b) => a.dateTime.isBefore(b.dateTime) ? a : b);
                  }

                  final localStartTime = nextOrOpenCheckInTime != null ? tz.TZDateTime.from(nextOrOpenCheckInTime.dateTime, location) : null;
                  final localEndTime = localStartTime != null && nextOrOpenCheckInTime != null ? localStartTime.add(nextOrOpenCheckInTime.duration) : null;
                  final formattedStartTime = localStartTime != null ? DateFormat('h:mm a').format(localStartTime) : '';
                  final formattedEndTime = localEndTime != null ? DateFormat('h:mm a').format(localEndTime) : '';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenWidth * 0.1),
                      Row(
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: screenWidth * 0.05, // Adjust font size based on screen width
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_placeName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Place name
                              Text(
                                _placeName!,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05, // Font size for location name
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              // SizedBox(height: screenWidth * 0.005), // Small gap between location and weather details

                              // Weather details (description, icon, and temperature)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Weather description
                                  if (userProvider.user?.locationSharingEnabled == true && _weatherType != null)
                                    Text(
                                      _weatherType!
                                          .split(' ') // Split the description into words
                                          .map((word) => word[0].toUpperCase() + word.substring(1)) // Capitalize the first letter of each word
                                          .join(' '), // Join the words back into a single string
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04, // Font size for weather description
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  SizedBox(width: screenWidth * 0.02), // Small gap between description and icon

                                  // Weather icon
                                  if (userProvider.user?.locationSharingEnabled == true && _weatherIconUrl != null)
                                    Image.network(
                                      _weatherIconUrl!,
                                      width: 60, // Width of the weather icon
                                      height: 60, // Height of the weather icon
                                    ),
                                  SizedBox(width: screenWidth * 0.02), // Small gap between icon and temperature

                                  // Temperature
                                  if (userProvider.user?.locationSharingEnabled == true && _weatherIconUrl != null)
                                    Text(
                                      '25°C', // Replace with actual temperature value
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04, // Font size for temperature
                                        fontWeight: FontWeight.normal, // Normal font weight for temperature
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: screenWidth * 0.1),
                      if (checkInTimes == null || checkInTimes.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                                child: Text(
                                  'No check in times set up',
                                  style: TextStyle(fontSize: screenWidth * 0.12, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                                child: Text(
                                  'Go to Settings and add a Schedule',
                                  style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.normal),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            Center(
                              child: GlassmorphismContainer(
                                child: Column(
                                  children: [
                                    SizedBox(height: screenWidth * 0.04),
                                    Text(
                                      nextOrOpenCheckInTime?.status == 'open' ? 'Check In Now' : 'Next Check In',
                                      style: TextStyle(fontSize: screenWidth * 0.07, fontWeight: FontWeight.normal),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: screenWidth * 0.02),
                                    if (nextOrOpenCheckInTime != null)
                                      Column(
                                        children: [
                                          Text(
                                            formattedStartTime,
                                            style: TextStyle(fontSize: screenWidth * 0.1, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          Icon(Icons.arrow_downward_outlined, size: screenWidth * 0.1),
                                          Text(
                                            formattedEndTime,
                                            style: TextStyle(fontSize: screenWidth * 0.1, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (nextOrOpenCheckInTime.status == 'pending' &&
                                              localStartTime != null &&
                                              localStartTime.day == DateTime.now().add(Duration(days: 1)).day &&
                                              localStartTime.month == DateTime.now().add(Duration(days: 1)).month &&
                                              localStartTime.year == DateTime.now().add(Duration(days: 1)).year)
                                            Text(
                                              '(Tomorrow)',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.05, // Adjust font size for "(Tomorrow)"
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black, // Set text color to black
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                        ],
                                      ),
                                    SizedBox(height: screenWidth * 0.05), // Add padding at the bottom
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.05),
                            // Add the "Help!" button here
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/i_need_help'); // Push to the "I Need Help" page
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red, // Red background
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 16.0), // Adjust padding for better spacing
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0), // Rounded corners
                                  ),
                                  elevation: 5, // Slight elevation for shadow effect
                                ),
                                icon: SizedBox(
                                  width: 48.0, // Width of the cross
                                  height: 48.0, // Height of the cross
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 12.0, // Thickness of the vertical bar
                                        height: 48.0, // Height of the vertical bar
                                        color: Colors.white, // White color for the cross
                                      ),
                                      Container(
                                        width: 48.0, // Width of the horizontal bar
                                        height: 12.0, // Thickness of the horizontal bar
                                        color: Colors.white, // White color for the cross
                                      ),
                                    ],
                                  ),
                                ),
                                label: const Padding(
                                  padding: EdgeInsets.only(left: 16.0), // Add more space between the icon and text
                                  child: Text(
                                    'I NEED HELP!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.0, // Increased font size for better visibility
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],)
    );
  }
}

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;

  const GlassmorphismContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // 90% of the screen width
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Decrease vertical padding
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Semi-transparent white
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Semi-transparent white border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5, // Limit height to 50% of screen height
            ),
            child: SingleChildScrollView(
              child: child, // Allow scrolling if content exceeds max height
            ),
          ),
        ),
      ),
    );
  }
}