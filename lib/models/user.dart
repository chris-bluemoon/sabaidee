import 'package:cloud_firestore/cloud_firestore.dart';

import 'check_in_time.dart'; // Add this import if CheckInTime is defined in another file

class User {
  final String uid;
  final String email;
  String name;
  String? address; // Add address field
  String? phoneNumber; // Add phone number field
  Map<String, String> country;
  final List<CheckInTime> checkInTimes;
  final List<Map<String, String>> followers;
  final List<Map<String, String>> watching;
  final String? fcmToken;
  final String referralCode;
  bool emojisEnabled;
  bool quotesEnabled;
  bool locationSharingEnabled; // Add locationSharingEnabled field

  User({
    required this.uid,
    required this.email,
    required this.name,
    this.address,
    this.phoneNumber,
    required this.country,
    required this.checkInTimes,
    required this.followers,
    required this.watching,
    this.fcmToken,
    required this.referralCode,
    required this.emojisEnabled,
    required this.quotesEnabled,
    required this.locationSharingEnabled, // Initialize locationSharingEnabled
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      address: data['address'], // Load address from Firestore
      phoneNumber: data['phoneNumber'], // Load phone number from Firestore
      country: Map<String, String>.from(data['country']),
      checkInTimes: (data['checkInTimes'] as List)
          .map((item) => CheckInTime.fromMap(item as Map<String, dynamic>))
          .toList(),
      followers: (data['followers'] as List<dynamic>? ?? [])
          .map((follower) => Map<String, String>.from(follower as Map))
          .toList(),
      watching: (data['watching'] as List<dynamic>? ?? [])
          .map((watchinger) => Map<String, String>.from(watchinger as Map))
          .toList(),
      fcmToken: data['fcmToken'],
      referralCode: data['referralCode'],
      emojisEnabled: data['emojisEnabled'] ?? true,
      quotesEnabled: data['quotesEnabled'] ?? true,
      locationSharingEnabled: data['locationSharingEnabled'] ?? false, // Load locationSharingEnabled from Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'address': address, // Include address in Firestore
      'phoneNumber': phoneNumber, // Include phone number in Firestore
      'country': country,
      'checkInTimes': checkInTimes.map((checkInTime) => checkInTime.toMap()).toList(),
      'followers': followers,
      'watching': watching,
      'fcmToken': fcmToken,
      'referralCode': referralCode,
      'emojisEnabled': emojisEnabled,
      'quotesEnabled': quotesEnabled,
      'locationSharingEnabled': locationSharingEnabled, // Include locationSharingEnabled in Firestore
    };
  }
}