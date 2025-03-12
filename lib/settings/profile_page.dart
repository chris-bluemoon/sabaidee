import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';
import 'package:sabaidee/utils/country_list.dart'; // Import the country list

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

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 60, // Set a consistent height for each box
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10), // Make the boxes more rounded
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
                      children: [
                        Icon(Icons.person_outline, size: screenWidth * 0.06, color: Colors.black),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Name',
                              hintStyle: TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                            enabled: _isEditing,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 60, // Set a consistent height for each box
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10), // Make the boxes more rounded
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
                      children: [
                        Icon(Icons.phone_outlined, size: screenWidth * 0.06, color: Colors.black),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              hintText: 'Phone',
                              hintStyle: TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                            enabled: _isEditing,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 60, // Set a consistent height for each box
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10), // Make the boxes more rounded
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
                      children: [
                        Icon(Icons.email_outlined, size: screenWidth * 0.06, color: Colors.black),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Email: ${user?.email ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045, // Set the font size relative to the screen width
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 60, // Set a consistent height for each box
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10), // Make the boxes more rounded
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
                      children: [
                        Icon(Icons.flag_outlined, size: screenWidth * 0.06, color: Colors.black),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            decoration: InputDecoration(
                              hintText: 'Country',
                              hintStyle: TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
                              border: InputBorder.none,
                            ),
                            items: getCountryNames().map((String country) {
                              return DropdownMenuItem<String>(
                                value: country,
                                child: Text(country, style: TextStyle(fontSize: screenWidth * 0.045)),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                                    'timezone': getCountryListWithTimezones()
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
                            ),
                            child: Text('SAVE', style: TextStyle(fontSize: screenWidth * 0.045)),
                          ),
                          const SizedBox(width: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey, // Set the background color to grey
                              foregroundColor: Colors.white, // Set the text color to white
                            ),
                            child: Text('CANCEL', style: TextStyle(fontSize: screenWidth * 0.045)),
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
                        ),
                        child: Text('EDIT', style: TextStyle(fontSize: screenWidth * 0.045)),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}