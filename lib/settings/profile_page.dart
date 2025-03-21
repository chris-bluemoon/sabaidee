import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/providers/user_provider.dart';
import 'package:sabaidee/utils/country_list2.dart'; // Import the country list

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _selectedCountry;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.user?.name ?? '');
    _phoneController = TextEditingController(text: userProvider.user?.phoneNumber ?? '');
    _selectedCountry = userProvider.user?.country['country']; // Initialize _selectedCountry
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.045, // Set the font size relative to the screen width
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.07, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg3.png',
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: appBarHeight + screenHeight * 0.08), // Add more space below the app bar
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassmorphismContainer(
                        height: screenHeight * 0.08, // Adjust height based on screen size
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: screenWidth * 0.055, color: Colors.black),
                            SizedBox(width: screenWidth * 0.04), // Make the gap relative to the screen size
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Name',
                                    hintStyle: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                  enabled: _isEditing,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02), // Adjust height based on screen size
                      GlassmorphismContainer(
                        height: screenHeight * 0.08, // Adjust height based on screen size
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, size: screenWidth * 0.055, color: Colors.black),
                            SizedBox(width: screenWidth * 0.04), // Make the gap relative to the screen size
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    hintText: 'Phone',
                                    hintStyle: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    return null;
                                  },
                                  enabled: _isEditing,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02), // Adjust height based on screen size
                      GlassmorphismContainer(
                        height: screenHeight * 0.08, // Adjust height based on screen size
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, size: screenWidth * 0.055, color: Colors.black),
                            SizedBox(width: screenWidth * 0.04), // Make the gap relative to the screen size
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  user?.email ?? 'Unknown',
                                  style: TextStyle(
                                    color: _isEditing ? Colors.black : Colors.grey[700],
                                    fontSize: screenWidth * 0.04, // Set the font size relative to the screen width
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02), // Adjust height based on screen size
                      GlassmorphismContainer(
                        height: screenHeight * 0.08, // Adjust height based on screen size
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: screenWidth * 0.055, color: Colors.black), // Change to location icon
                            SizedBox(width: screenWidth * 0.04), // Make the gap relative to the screen size
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCountry,
                                decoration: InputDecoration(
                                  hintText: 'Country',
                                  hintStyle: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero, // Remove default padding
                                ),
                                isExpanded: true, // Ensure the dropdown button takes up available space
                                items: getCountryList2().map((country) {
                                  return DropdownMenuItem<String>(
                                    value: country['country'],
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset(
                                              'assets/flags/${country['filename']}',
                                              width: screenWidth * 0.055, // Set the width relative to the screen width
                                              height: screenWidth * 0.055, // Set the height relative to the screen width
                                            ),
                                            SizedBox(width: screenWidth * 0.02), // Make the gap relative to the screen size
                                            Text(country['country']!, style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04)),
                                          ],
                                        ),
                                        const Divider(), // Add a divider between items
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: _isEditing ? (String? newValue) {
                                  setState(() {
                                    _selectedCountry = newValue;
                                  });
                                } : null,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your country';
                                  }
                                  return null;
                                },
                                selectedItemBuilder: (BuildContext context) {
                                  return getCountryList2().map((country) {
                                    return Text(country['country']!, style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04));
                                  }).toList();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(), // Add a spacer to push the buttons to the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Center(
                    child: _isEditing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    userProvider.updateUser(
                                      name: _nameController.text,
                                      phoneNumber: _phoneController.text,
                                      country: {
                                        'country': _selectedCountry ?? '',
                                        'timezone': getCountryList2()
                                            .firstWhere((element) => element['country'] == _selectedCountry)['timezone'] ?? '',
                                      },
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Profile updated')),
                                    );
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black, // Set the background color to black
                                  foregroundColor: Colors.white, // Set the text color to white
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20), // Match the border radius of the GlassmorphismContainer
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0), // Add padding for a consistent look
                                ),
                                child: Text('SAVE', style: TextStyle(fontSize: screenWidth * 0.04)),
                              ),
                              SizedBox(width: screenWidth * 0.04), // Make the gap relative to the screen size
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey, // Set the background color to grey
                                  foregroundColor: Colors.white, // Set the text color to white
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20), // Match the border radius of the GlassmorphismContainer
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0), // Add padding for a consistent look
                                ),
                                child: Text('CANCEL', style: TextStyle(fontSize: screenWidth * 0.04)),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Set the background color to black
                              foregroundColor: Colors.white, // Set the text color to white
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20), // Match the border radius of the GlassmorphismContainer
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0), // Add padding for a consistent look
                            ),
                            child: Text('EDIT', style: TextStyle(fontSize: screenWidth * 0.04)),
                          ),
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

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double height;

  const GlassmorphismContainer({required this.child, required this.height, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height, // Set a consistent height for each box
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Semi-transparent white
            borderRadius: BorderRadius.circular(20),
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
