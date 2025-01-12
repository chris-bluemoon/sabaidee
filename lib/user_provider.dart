import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> addCheckInTime(TimeOfDay time) async {
    if (_user != null) {
      final checkInTime = CheckInTime(time: time, status: 'pending');
      _user!.checkInTimes.add(checkInTime);

      // Update Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'checkInTimes': FieldValue.arrayUnion([{
          'hour': time.hour,
          'minute': time.minute,
          'status': 'pending',
        }])
      });

      notifyListeners();
    }
  }


  void setCheckInStatus(TimeOfDay time, String status) async {
    if (_user != null) {
      for (var checkInTime in _user!.checkInTimes) {
        log(checkInTime.time.toString());
        log(time.toString());
        if (checkInTime.time == time) {
          checkInTime.status = status;
          break;
        }
      }
            // Update Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'checkInTimes': _user!.checkInTimes.map((checkInTime) => {
          'hour': checkInTime.time.hour,
          'minute': checkInTime.time.minute,
          'status': checkInTime.status,
        }).toList(),
      });
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String phoneNumber) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      _user = User(id: userCredential.user!.uid, email: email, name: 'Dummy', phoneNumber: phoneNumber, checkInTimes: []);
      
      // Add user to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': 'Dummy',
        'phoneNumber': phoneNumber,
        'checkInTimes': [],
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        _user = User(id: googleUser.id, name: googleUser.displayName ?? googleUser.email, checkInTimes: [], email: googleUser.email, phoneNumber: null);
        notifyListeners();
      }
    } catch (error) {
      print('Google sign-in failed: $error');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await _fetchUserData(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw Exception('Network error: Please check your internet connection.');
      } else {
        throw Exception('Failed to sign in: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (error) {
      print('Sign out failed: $error');
    }
    _user = null;
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    // Fetch user data from your database and set the _user object
    // This is a placeholder implementation
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    _user = User(
      id: uid,
      email: userDoc['email'],
      name: userDoc['name'],
      phoneNumber: userDoc['phoneNumber'],
      checkInTimes: (userDoc['checkInTimes'] as List).map((time) => CheckInTime(time: TimeOfDay(hour: time['hour'], minute: time['minute']), status: time['status'])).toList(),
    );
    notifyListeners();
  }
}

class CheckInTime {
  TimeOfDay time;
  String status;

  CheckInTime({required this.time, required this.status});
}

class User {
  final String id;
  final String email;
  final String name;
  List<CheckInTime> checkInTimes;

  User({required this.id, required this.email, required this.name, required this.checkInTimes, required phoneNumber});
}