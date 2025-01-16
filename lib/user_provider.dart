import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sabaidee/main.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timer;

  UserProvider() {
    _startTimer();
  }

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
      await _firestore.collection('users').doc(_user!.uid).update({
        'checkInTimes': FieldValue.arrayUnion([{
          'hour': time.hour,
          'minute': time.minute,
          'status': 'pending',
        }])
      });

      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user as User?;

        if (firebaseUser != null) {
          final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (!userDoc.exists) {
            // Create a new user record in Firestore
            await _firestore.collection('users').doc(firebaseUser.uid).set({
              'email': firebaseUser.email,
              'name': 'TBC',
              'checkInTimes': [],
            });
          }

          // Fetch user data from Firestore
          await _fetchUserData(firebaseUser.uid);
        }
      }
    } catch (error) {
      print('Google sign-in failed: $error');
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
      await _firestore.collection('users').doc(_user!.uid).update({
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
      _user = User(uid: userCredential.user!.uid, email: email, name: 'Dummy', phoneNumber: phoneNumber, checkInTimes: []);
      
      // Add user to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': 'TBC',
        'phoneNumber': phoneNumber,
        'checkInTimes': [],
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign up: $e');
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
      uid: uid,
      email: userDoc['email'],
      name: userDoc['name'],
      phoneNumber: userDoc['phoneNumber'],
      checkInTimes: (userDoc['checkInTimes'] as List).map((time) => CheckInTime(time: TimeOfDay(hour: time['hour'], minute: time['minute']), status: time['status'])).toList(),
    );
    _startTimer();
    notifyListeners();
  }

  List<CheckInTime> get scheduleTimes {
      return _user?.checkInTimes ?? [];
  }
  
  List<CheckInTime> get pendingCheckInTimes {
    return _user?.checkInTimes.where((time) => time.status == 'pending').toList() ?? [];
  }
  
  Future<void> deleteCheckInTime(TimeOfDay time) async {
      if (_user != null) {
        _user!.checkInTimes.removeWhere((checkInTime) => checkInTime.time == time);
  
        // Update Firestore
        await _firestore.collection('users').doc(_user!.uid).update({
          'checkInTimes': FieldValue.arrayRemove([{
            'hour': time.hour,
            'minute': time.minute,
            'status': 'pending',
          }])
        });
  
        notifyListeners();
      }
    }

  void _startTimer() {
    log('Starting timer');
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForMissedCheckInTimes();
    });
  }

  Future<void> _checkForMissedCheckInTimes() async {
    final now = TimeOfDay.now();
    final nextPendingCheckInTime = this.nextPendingCheckInTime;
    log('Checking time - now: ${now.hour}:${now.minute}, nextPendingCheckInTime: ${nextPendingCheckInTime?.time.hour}:${nextPendingCheckInTime?.time.minute}');
    if (nextPendingCheckInTime != null) {
      if (nextPendingCheckInTime.time.hour < now.hour || (nextPendingCheckInTime.time.hour == now.hour && nextPendingCheckInTime.time.minute < now.minute)) {
        await _showAlert();
      }
    }
  }

  Future<void> _showAlert() async {
    // Delay the execution to ensure the context is available
    if (navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Missed Check-In'),
              content: const Text('You have missed a check-in time!'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        log('Navigator context is null, cannot show alert');
      }
  }

  CheckInTime? get nextPendingCheckInTime {
    final pendingCheckInTimes = _user?.checkInTimes.where((time) => time.status == 'pending').toList() ?? [];
    if (pendingCheckInTimes.isEmpty) return null;

    final now = TimeOfDay.now();
    final futureCheckInTimes = pendingCheckInTimes
        .where((time) => time.time.hour > now.hour || (time.time.hour == now.hour && time.time.minute > now.minute))
        .toList();

    if (futureCheckInTimes.isNotEmpty) {
      return futureCheckInTimes.reduce((a, b) => a.time.hour < b.time.hour || (a.time.hour == b.time.hour && a.time.minute < b.time.minute) ? a : b);
    } else {
      return pendingCheckInTimes.reduce((a, b) => a.time.hour < b.time.hour || (a.time.hour == b.time.hour && a.time.minute < b.time.minute) ? a : b);
    }
  }

}

class CheckInTime {
  TimeOfDay time;
  String status;

  CheckInTime({required this.time, required this.status});
}

class User {
  final String uid;
  final String email;
  final String name;
  List<CheckInTime> checkInTimes;

  User({required this.uid, required this.email, required this.name, required this.checkInTimes, required phoneNumber});
}