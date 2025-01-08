import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _phoneNumber;
  List<TimeOfDay>? _checkInTimes;
  List<TimeOfDay>? _scheduleTimes;

  User? get user => _user;
  String? get phoneNumber => _phoneNumber;
  List<TimeOfDay>? get checkInTimes => _checkInTimes;
  List<TimeOfDay>? get scheduleTimes => _scheduleTimes;

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserData(user.uid);
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserData(String uid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      _phoneNumber = userDoc['phoneNumber'];
      _checkInTimes = (userDoc['checkInTimes'] as List<dynamic>?)
          ?.map((timestamp) {
            final dateTime = (timestamp as Timestamp).toDate();
            return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
          })
          .toList();
      _scheduleTimes = (userDoc['scheduleTimes'] as List<dynamic>?)
          ?.map((timestamp) {
            final dateTime = (timestamp as Timestamp).toDate();
            return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
          })
          .toList();
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    await _fetchUserData(userCredential.user!.uid);
  }

  Future<void> signUp(String email, String password, String phoneNumber) async {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _phoneNumber = phoneNumber;
    await _saveUserToFirestore(userCredential.user, phoneNumber);
    notifyListeners();
  }

  Future<void> _saveUserToFirestore(User? user, String phoneNumber) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'phoneNumber': phoneNumber,
        'checkInTimes': [],
        'scheduleTimes': [],
      });
    }
  }

  Future<void> addCheckInTime(TimeOfDay timeOfDay) async {
    if (_user != null) {
      _checkInTimes ??= [];
      _checkInTimes!.add(timeOfDay);
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'checkInTimes': _checkInTimes!.map((time) => Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, time.hour, time.minute))).toList(),
      });
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}