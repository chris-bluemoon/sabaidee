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
      final now = DateTime.now();
      final checkInTime = CheckInTime(
        dateTime: DateTime(now.year, now.month, now.day, time.hour, time.minute),
        status: 'pending',
        duration: const Duration(minutes: 5), // Set default duration to 5 minutes
      );
      _user!.checkInTimes.add(checkInTime);

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'checkInTimes': FieldValue.arrayUnion([{
          'dateTime': checkInTime.dateTime.toIso8601String(),
          'status': 'pending',
          'duration': checkInTime.duration.inSeconds, // Store duration in seconds
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
              'watching': [],
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

  void _resetCheckInStatuses() async {
    if (_user != null) {
      for (var checkInTime in _user!.checkInTimes) {
          checkInTime.status = 'pending';
      await _firestore.collection('users').doc(_user!.uid).update({
        'checkInTimes': _user!.checkInTimes.map((checkInTime) => {
          'hour': checkInTime.dateTime.hour,
          'minute': checkInTime.dateTime.minute,
          'status': checkInTime.status,
        }).toList(),
      });
      }
            // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'checkInTimes': _user!.checkInTimes.map((checkInTime) => {
          'hour': checkInTime.dateTime.hour,
          'minute': checkInTime.dateTime.minute,
          'status': checkInTime.status,
        }).toList(),
      });
      notifyListeners();
    }
  }
  void setCheckInStatus(TimeOfDay time, String status) async {
    if (_user != null) {
      for (var checkInTime in _user!.checkInTimes) {
        log(checkInTime.dateTime.toString());
        log(time.toString());
        if (checkInTime.dateTime.hour == time.hour && checkInTime.dateTime.minute == time.minute) {
          checkInTime.status = status;
          break;
        }
      }
            // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'checkInTimes': _user!.checkInTimes.map((checkInTime) => {
          'hour': checkInTime.dateTime.hour,
          'minute': checkInTime.dateTime.minute,
          'status': checkInTime.status,
        }).toList(),
      });
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name, String phoneNumber) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      _user = User(uid: userCredential.user!.uid, email: email, name: 'Dummy', phoneNumber: phoneNumber, checkInTimes: [], relatives: [], watching: []);
      
      // Add user to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'checkInTimes': [],
        'relatives': [],
        'watching': [],
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
      for (Map<String, String> relative in _user!.relatives) {
        String relativeUid = relative['uid']!;
        final userDoc = await _firestore.collection('users').doc(relativeUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          relativeEmails[relativeUid] = userData['email'];
        }
      }
    }
    return relativeEmails;
  }
  Future<Map<String, Map<String, String>>> fetchWatchingNamesAndStatuses() async {
    final Map<String, Map<String, String>> watchingNamesAndStatuses = {};
    if (_user != null) {
      for (var watching in _user!.watching) {
        final watchingUid = watching['uid'];
        final status = watching['status'];
        final userDoc = await _firestore.collection('users').doc(watchingUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          watchingNamesAndStatuses[watchingUid!] = {
            'name': userData['name'],
            'status': status!,
          };
        }
      }
    }
    return watchingNamesAndStatuses;
  }
  Future<Map<String, Map<String, String>>> fetchRelativeNamesAndStatuses() async {
    final Map<String, Map<String, String>> relativeNamesAndStatuses = {};
    if (_user != null) {
      for (var relative in _user!.relatives) {
        final relativeUid = relative['uid'];
        final status = relative['status'];
        final userDoc = await _firestore.collection('users').doc(relativeUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          relativeNamesAndStatuses[relativeUid!] = {
            'name': userData['name'],
            'status': status!,
          };
        }
      }
    }
    return relativeNamesAndStatuses;
  }

  Future<void> _fetchUserData(String uid) async {
    // Fetch user data from your database and set the _user object
    // This is a placeholder implementation
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    final now = DateTime.now();
    _user = User(
      uid: uid,
      email: userDoc['email'],
      name: userDoc['name'],
      phoneNumber: userDoc['phoneNumber'],
      checkInTimes: (userDoc['checkInTimes'] as List).map((time) => CheckInTime(dateTime: DateTime(now.year, now.month, now.day, time['hour'], time['minute']), status: time['status'], duration: Duration(minutes: time['duration']))).toList(),
      relatives: List<Map<String, String>>.from(userDoc['relatives'] ?? []),
      watching: List<Map<String, String>>.from(userDoc['watching'] ?? []),
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
        _user!.checkInTimes.removeWhere((checkInTime) => checkInTime.dateTime.hour == time.hour && checkInTime.dateTime.minute == time.minute);
  
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
      _checkForMissedCheckInTimesFromWatching();
        // log('Raising notification');
        // await _showNotification();
    });
  }

  Future<void> _checkForMissedCheckInTimes() async {
    log('Checking for missed check-in times');
    final now = TimeOfDay.now();
    final nextPendingCheckInTime = this.nextPendingCheckInTime;
    log('Checking time - now: ${now.hour}:${now.minute}, nextPendingCheckInTime: ${nextPendingCheckInTime?.dateTime.hour}:${nextPendingCheckInTime?.dateTime.minute}');
    if (nextPendingCheckInTime != null) {
      if (nextPendingCheckInTime.dateTime.hour < now.hour || (nextPendingCheckInTime.dateTime.hour == now.hour && nextPendingCheckInTime.dateTime.minute < now.minute)) {
        setCheckInStatus(TimeOfDay(hour: nextPendingCheckInTime.dateTime.hour, minute: nextPendingCheckInTime.dateTime.minute), 'missed');
        // await _showNotification('Missed Check-In', 'You have missed a check-in time at ${nextPendingCheckInTime.time.hour}:${nextPendingCheckInTime.time.minute}');
        _showAlert('You missed a Check-In!');
      }
    }
  }
  
  Future<void> _showNotification(title, description) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'missed_check_in_channel',
      'Missed Check-In',
      channelDescription: 'Generic notification for missed check-in times',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      description,
      platformChannelSpecifics,
      payload: 'missed_check_in',
    );
  }

  Future<void> _showAlert(String title) async {
    // Delay the execution to ensure the context is available
    if (navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: const Text('Missed a check-in time!'),
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
        .where((time) => time.dateTime.hour > now.hour || (time.dateTime.hour == now.hour && time.dateTime.minute > now.minute))
        .toList();

    if (futureCheckInTimes.isNotEmpty) {
      return futureCheckInTimes.reduce((a, b) => a.dateTime.hour < b.dateTime.hour || (a.dateTime.hour == b.dateTime.hour && a.dateTime.minute < b.dateTime.minute) ? a : b);
    } else {
      return pendingCheckInTimes.reduce((a, b) => a.dateTime.hour < b.dateTime.hour || (a.dateTime.hour == b.dateTime.hour && a.dateTime.minute < b.dateTime.minute) ? a : b);
    }
  }

  List<Map<String, String>> get watching {
    return _user?.watching ?? [];
  }
  List<Map<String, String>> get relatives {
    return _user?.relatives ?? [];
  }

  Future<void> addRelative(String relativeUid, String status) async {
    if (_user != null) {
      _user!.relatives.add({'uid': relativeUid, 'status': status});

      // Update Firestore for the current user
      await _firestore.collection('users').doc(_user!.uid).update({
        'relatives': FieldValue.arrayUnion([{'uid': relativeUid, 'status': status}]),
      });

      // Update Firestore for the relative user
      await _firestore.collection('users').doc(relativeUid).update({
        'watching': FieldValue.arrayUnion([{'uid': _user!.uid, 'status': status}]),
      });

      notifyListeners();
    }
  }

  Future<void> _checkForMissedCheckInTimesFromWatching() async {
    log('Checking for missed check-in times from watching');
    if (_user != null) {
      for (var watching in _user!.watching) {
        final watchingUid = watching['uid'];
        if (watchingUid != null) {
          final userDoc = await _firestore.collection('users').doc(watchingUid).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final checkInTimes = (userData['checkInTimes'] as List<dynamic>).map((e) => CheckInTime.fromMap(e)).toList();
            final now = TimeOfDay.now();

            for (var checkInTime in checkInTimes) {
              if (checkInTime.status == 'pending' &&
                  (checkInTime.dateTime.hour < now.hour || (checkInTime.dateTime.hour == now.hour && checkInTime.dateTime.minute < now.minute))) {
                // Missed check-in time found
                log('User $watchingUid missed check-in time at ${checkInTime.dateTime.hour}:${checkInTime.dateTime.minute}');
                // await _showNotification('Missed Check-In', 'User $watchingUid missed a check-in time at ${checkInTime.time.hour}:${checkInTime.time.minute}');
                _showAlert('User $watchingUid missed check-in time');
              }
            }
          }
        }
      }
    }
  }

  // Future<void> addWatching(String watchingUid, String status) async {
  //   if (_user != null) {
  //     _user!.watching.add({'uid': watchingUid, 'status': status});

  //     // Update Firestore
  //     await _firestore.collection('users').doc(_user!.uid).update({
  //       'watching': FieldValue.arrayUnion([{'uid': watchingUid, 'status': status}]),
  //     });

  //     notifyListeners();
  //   }
  // }

}

class CheckInTime {
  final DateTime dateTime;
  String status;
  final Duration duration; // Add duration field

  CheckInTime({required this.dateTime, required this.status, required this.duration});

  factory CheckInTime.fromMap(Map<String, dynamic> map) {
    return CheckInTime(
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'],
      duration: Duration(minutes: map['duration']), // Parse duration from minutes
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'duration': duration.inMinutes, // Store duration in minutes
    };
  }
}
class User {
  final String uid;
  final String email;
  final String name;
  final String phoneNumber;
  final List<CheckInTime> checkInTimes;
  final List<Map<String, String>> relatives;
  final List<Map<String, String>> watching;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.checkInTimes,
    required this.relatives,
    required this.watching,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      checkInTimes: (data['checkInTimes'] as List)
          .map((item) => CheckInTime.fromMap(item as Map<String, dynamic>))
          .toList(),
      relatives: List<Map<String, String>>.from(data['relatives']),
      watching: List<Map<String, String>>.from(data['watching']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'checkInTimes': checkInTimes.map((checkInTime) => checkInTime.toMap()).toList(),
      'relatives': relatives,
      'watching': watching,
    };
  }
}