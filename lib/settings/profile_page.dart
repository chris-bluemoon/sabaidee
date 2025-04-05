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
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  String? _selectedCountry;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.user?.name ?? '');
    _addressController = TextEditingController(text: userProvider.user?.address ?? '');
    _phoneController = TextEditingController(text: userProvider.user?.phoneNumber ?? '');
    _selectedCountry = userProvider.user?.country['country'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Prevent bottom overflow when the keyboard opens
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.07,
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
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight, // Ensure the content takes at least the full height
              ),
              child: Padding(
                padding: EdgeInsets.all(screenHeight * 0.02),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: appBarHeight + screenHeight * 0.08),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            GlassmorphismContainer(
                              height: screenHeight * 0.08,
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, size: screenWidth * 0.055, color: Colors.black),
                                  SizedBox(width: screenWidth * 0.04),
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
                            SizedBox(height: screenHeight * 0.02),
                            // Address Field
                            GlassmorphismContainer(
                              height: screenHeight * 0.08,
                              child: Row(
                                children: [
                                  Icon(Icons.home_outlined, size: screenWidth * 0.055, color: Colors.black),
                                  SizedBox(width: screenWidth * 0.04),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextFormField(
                                        controller: _addressController,
                                        decoration: InputDecoration(
                                          hintText: 'Address',
                                          hintStyle: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                          border: InputBorder.none,
                                        ),
                                        style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                        enabled: _isEditing,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Phone Number Field
                            GlassmorphismContainer(
                              height: screenHeight * 0.08,
                              child: Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: screenWidth * 0.055, color: Colors.black),
                                  SizedBox(width: screenWidth * 0.04),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          hintText: 'Phone Number',
                                          hintStyle: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                          border: InputBorder.none,
                                        ),
                                        style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                        enabled: _isEditing,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Country Dropdown
                            GlassmorphismContainer(
                              height: screenHeight * 0.08,
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: screenWidth * 0.055, color: Colors.black),
                                  SizedBox(width: screenWidth * 0.04),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: getCountryList2().any((country) => country['country'] == _selectedCountry)
                                          ? _selectedCountry
                                          : null, // Ensure the value is valid or set to null
                                      decoration: InputDecoration(
                                        hintText: 'Country',
                                        hintStyle: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      isExpanded: true,
                                      items: getCountryList2().map((country) {
                                        return DropdownMenuItem<String>(
                                          value: country['country'],
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                'assets/flags/${country['filename']}',
                                                width: screenWidth * 0.055,
                                                height: screenWidth * 0.055,
                                              ),
                                              SizedBox(width: screenWidth * 0.02),
                                              Text(
                                                country['country']!,
                                                style: TextStyle(color: _isEditing ? Colors.black : Colors.grey[700], fontSize: screenWidth * 0.04),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _isEditing
                                          ? (String? newValue) {
                                              setState(() {
                                                _selectedCountry = newValue;
                                              });
                                            }
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.05),
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
                                            country: {
                                              'country': _selectedCountry ?? '',
                                              'timezone': getCountryList2()
                                                  .firstWhere(
                                                    (element) => element['country'] == _selectedCountry,
                                                    orElse: () => {'timezone': ''}, // Provide a default value
                                                  )['timezone'] ?? '',
                                            },
                                            address: _addressController.text,
                                            phoneNumber: _phoneController.text,
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
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.04, vertical: screenHeight * 0.015),
                                      ),
                                      child: Text('SAVE', style: TextStyle(fontSize: screenWidth * 0.04)),
                                    ),
                                    SizedBox(width: screenWidth * 0.04),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.04, vertical: screenHeight * 0.015),
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
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.04, vertical: screenHeight * 0.015),
                                  ),
                                  child: Text('EDIT', style: TextStyle(fontSize: screenWidth * 0.04)),
                                ),
                        ),
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
  final double height;

  const GlassmorphismContainer({required this.child, required this.height, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
