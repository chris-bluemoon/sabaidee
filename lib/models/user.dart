import 'package:cloud_firestore/cloud_firestore.dart';

import 'check_in_time.dart'; // Add this import if CheckInTime is defined in another file

class User {
  final String uid;
  final String email;
  String name;
  Map<String, String> country; // Change country to a map with timezone
  final List<CheckInTime> checkInTimes;
  final List<Map<String, String>> followers;
  final List<Map<String, String>> watching;
  final String? fcmToken;
  final String referralCode;
  bool emojisEnabled; // Add the emojisEnabled field

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.country,
    required this.checkInTimes,
    required this.followers,
    required this.watching,
    this.fcmToken,
    required this.referralCode,
    required this.emojisEnabled, // Initialize the emojisEnabled field
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      country: Map<String, String>.from(data['country']),
      checkInTimes: (data['checkInTimes'] as List)
          .map((item) => CheckInTime.fromMap(item as Map<String, dynamic>))
          .toList(),
      followers: List<Map<String, String>>.from(data['followers']),
      watching: List<Map<String, String>>.from(data['watching']),
      fcmToken: data['fcmToken'],
      referralCode: data['referralCode'],
      emojisEnabled: data['emojisEnabled'] ?? true, // Default to true if not set
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'country': country,
      'checkInTimes': checkInTimes.map((checkInTime) => checkInTime.toMap()).toList(),
      'followers': followers,
      'watching': watching,
      'fcmToken': fcmToken,
      'referralCode': referralCode,
      'emojisEnabled': emojisEnabled, // Include emojisEnabled in the map
    };
  }
}