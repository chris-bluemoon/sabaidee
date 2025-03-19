import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/home_page.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:sabaidee/utils/country_list2.dart'; // Import the country list

class CountrySelectionPage extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const CountrySelectionPage({
    required this.name,
    required this.email,
    required this.password,
    super.key,
  });

  @override
  _CountrySelectionPageState createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<CountrySelectionPage> {
  String? _selectedCountry = 'United Kingdom'; // Set default value to 'UK'
  bool _isLoading = false;
  String? _selectedTimeZone = 'UTC+00:00'; // Define the _selectedTimeZone variable

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    // Get the selected country's timezone
    final selectedCountry = getCountryList2().firstWhere(
      (country) => country['country'] == _selectedCountry,
      orElse: () => {'timezone': 'UTC+00:00'},
    );

    try {
      await Provider.of<UserProvider>(context, listen: false).signUp(
        widget.email,
        widget.password,
        widget.name,
        '123', // Default phone number
        {
          'country': _selectedCountry ?? '',
          'timezone': selectedCountry['timezone'] ?? 'UTC+00:00',
        },
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (mounted) {
        log(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: MediaQuery.of(context).size.width * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: const Text('Select Country', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassmorphismContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedCountry, // Set the initial value
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black), // Set the border color to black
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black), // Set the border color to black
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black), // Set the border color to black
                          ),
                        ),
                        items: getCountryList2()
                            .map((country) => DropdownMenuItem(
                                  value: country['country'],
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/flags/${country['filename']}' ?? '', // Assuming 'flag' contains the path to the flag image
                                        width: 34,
                                        height: 24,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(country['country'] ?? ''),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            // Update the selected timezone based on the selected country
                            final selectedCountry = getCountryList2().firstWhere(
                              (country) => country['country'] == value,
                              orElse: () => {'timezone': 'UTC+00:00'},
                            );
                            _selectedTimeZone = selectedCountry['timezone'];
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a country';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _selectedCountry != null && !_isLoading
                            ? _submit
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Set the background color to black
                          foregroundColor: Colors.white, // Set the text color to white
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // Change to 10.0 for squared off corners
                          ),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : const Text('SUBMIT'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;

  const GlassmorphismContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10), // Change to 10 for squared off corners
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Semi-transparent white
            borderRadius: BorderRadius.circular(10), // Change to 10 for squared off corners
            border: Border.all(
              color: Colors.white.withOpacity(0.3), // Semi-transparent white border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}