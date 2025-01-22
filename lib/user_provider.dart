import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
              'relatives': [],
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
      _user = User(uid: userCredential.user!.uid, email: email, name: 'Dummy', phoneNumber: phoneNumber, checkInTimes: [], relatives: []);
      
      // Add user to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': 'TBC',
        'phoneNumber': phoneNumber,
        'checkInTimes': [],
        'relatives': [],
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

  Future<Map<String, String>> fetchRelativeEmails() async {
    final Map<String, String> relativeEmails = {};
    if (_user != null) {
      for (String relativeUid in _user!.relatives) {
        final userDoc = await _firestore.collection('users').doc(relativeUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          relativeEmails[relativeUid] = userData['email'];
        }
      }
    }
    return relativeEmails;
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
      relatives: List<String>.from(userDoc['relatives'] ?? []),
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

  void _startTimer() async {
    log('Starting timer');
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      _checkForMissedCheckInTimes();
        log('Raising notification');
        await _showNotification();
    });
  }

  Future<void> _checkForMissedCheckInTimes() async {
    final now = TimeOfDay.now();
    final nextPendingCheckInTime = this.nextPendingCheckInTime;
    log('Checking time - now: ${now.hour}:${now.minute}, nextPendingCheckInTime: ${nextPendingCheckInTime?.time.hour}:${nextPendingCheckInTime?.time.minute}');
    if (nextPendingCheckInTime != null) {
      if (nextPendingCheckInTime.time.hour < now.hour || (nextPendingCheckInTime.time.hour == now.hour && nextPendingCheckInTime.time.minute < now.minute)) {
        setCheckInStatus(nextPendingCheckInTime.time, 'missed');
        await _showNotification();
      }
    }
  }
  
  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'missed_check_in_channel',
      'Missed Check-In',
      channelDescription: 'Notification for missed check-in times',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Missed Check-In',
      'You have missed a check-in time!',
      platformChannelSpecifics,
      payload: 'missed_check_in',
    );
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

    List<String> get relatives {
    return _user?.relatives ?? [];
  }

  Future<void> addRelative(String relativeUid) async {
    if (_user != null) {
      _user!.relatives.add(relativeUid);

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'relatives': FieldValue.arrayUnion([relativeUid]),
      });

      notifyListeners();
    }
  }

}

class CheckInTime {
  TimeOfDay time;
  String status;

  CheckInTime({required this.time, required this.status});

  factory CheckInTime.fromMap(Map<String, dynamic> map) {
    return CheckInTime(
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': time.hour,
      'minute': time.minute,
      'status': status,
    };
  }
}

class User {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final List<CheckInTime> checkInTimes;
  final List<String> relatives; // List of relative user IDs

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.checkInTimes,
    required this.relatives,
  });

    factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      checkInTimes: (data['checkInTimes'] as List<dynamic>).map((e) => CheckInTime.fromMap(e)).toList(),
      relatives: List<String>.from(data['relatives'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'checkInTimes': checkInTimes.map((e) => e.toMap()).toList(),
      'relatives': relatives,
    };
  }

}