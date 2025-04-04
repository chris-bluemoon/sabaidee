import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/country_selection_page.dart';
import 'package:sabaidee/home_page.dart';

import 'providers/user_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final bool _isLoading = false;
  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(false);

  void _validateForm() {
    _isFormValid.value = _formKey.currentState?.validate() ?? false;
  }

  void _navigateToCountrySelection() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CountrySelectionPage(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {

    try {
      await Provider.of<UserProvider>(context, listen: false).signUp(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign up: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
        });
      }
    }
  }
  
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _nameController.removeListener(_validateForm);
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: screenWidth * 0.08, // Set the size relative to the screen width
          ),
          onPressed: () {
            Navigator.pop(context); // Go back to the settings page
          },
        ),
        title: const Text('SIGN UP', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              onChanged: _validateForm,
              child: ListView(
                children: [
                  GlassmorphismContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              floatingLabelBehavior: FloatingLabelBehavior.never, // Prevent label from moving up
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0), // Change to 10.0 for squared off corners
                                borderSide: BorderSide.none, // Remove the black border
                              ),
                              prefixIcon: const Icon(Icons.person), // Add person icon
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              floatingLabelBehavior: FloatingLabelBehavior.never, // Prevent label from moving up
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0), // Change to 10.0 for squared off corners
                                borderSide: BorderSide.none, // Remove the black border
                              ),
                              prefixIcon: const Icon(Icons.email), // Add email icon
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              floatingLabelBehavior: FloatingLabelBehavior.never, // Prevent label from moving up
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0), // Change to 10.0 for squared off corners
                                borderSide: BorderSide.none, // Remove the black border
                              ),
                              prefixIcon: const Icon(Icons.lock), // Add password icon
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder<bool>(
                            valueListenable: _isFormValid,
                            builder: (context, isFormValid, child) {
                              return ElevatedButton(
                                onPressed: isFormValid ? _submit : null, // Use _submit here
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
                                    : const Text('NEXT'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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