import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    // _startTimer();
  }

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  
  Future<void> addCheckInTime(DateTime dateTime) async {
    if (_user != null) {
      final utcDateTime = dateTime.toUtc(); // Convert to UTC
      final checkInTime = CheckInTime(
        dateTime: utcDateTime,
        status: 'pending',
        duration: const Duration(minutes: 5), // Set default duration to 5 minutes
      );
      log('Adding check-in time for user: ${checkInTime.dateTime.toIso8601String()}');
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
void setCheckInStatus(DateTime dateTime, String status) async {
  if (_user != null) {
    for (var checkInTime in _user!.checkInTimes) {
      log('Setting status to $status for user stored checkInTime: ${checkInTime.dateTime.toString()}');
      log('With time supplied by next_check_page: ${dateTime.toString()}');
      if (checkInTime.dateTime == dateTime) {
        checkInTime.status = status;
        break;
      }
    }
    // Update Firestore
    await _firestore.collection('users').doc(_user!.uid).update({
      'checkInTimes': _user!.checkInTimes.map((checkInTime) => {
        'dateTime': checkInTime.dateTime.toIso8601String(),
        'status': checkInTime.status,
        'duration': checkInTime.duration.inSeconds, // Ensure duration is included
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
  DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
  log(userDoc.data().toString());
  // final now = DateTime.now();
  _user = User(
    uid: uid,
    email: userDoc['email'],
    name: userDoc['name'],
    phoneNumber: userDoc['phoneNumber'],
    checkInTimes: (userDoc['checkInTimes'] as List).map((time) {
      log(time.toString());
      return CheckInTime(
        dateTime: DateTime.parse(time['dateTime']),
        // dateTime: time['dateTime'].toDate(),
        // dateTime: DateTime(now.year, now.month, now.day, 
          // time['hour'], 
          // time['minute']),
        status: time['status'],
        duration: Duration(minutes: time['duration'] ?? 0), // Provide a default value if duration is null
      );
    }).toList(),
    relatives: (userDoc['relatives'] as List).map((relative) => Map<String, String>.from(relative)).toList(),
    watching: (userDoc['watching'] as List).map((watching) => Map<String, String>.from(watching)).toList(),
    // relatives: List<Map<String, String>>.from(userDoc['relatives'] ?? []),
    // watching: List<Map<String, String>>.from(userDoc['watching'] ?? []),
  );
  notifyListeners();
}

  List<CheckInTime> get scheduleTimes {
      return _user?.checkInTimes ?? [];
  }
  
  List<CheckInTime> get pendingOrOpenCheckInTimes {
    return _user?.checkInTimes.where((time) => time.status == 'pending' || time.status == 'open').toList() ?? [];
  }
  
Future<void> deleteCheckInTime(CheckInTime checkInTime) async {
  if (_user != null) {
    // Remove the check-in time from the local list
    _user!.checkInTimes.removeWhere((existingCheckInTime) => existingCheckInTime.dateTime == checkInTime.dateTime);

    // Update Firestore
    log('About to delete check-in time for user: ${checkInTime.dateTime.toIso8601String()}');
    log(checkInTime.dateTime.toIso8601String());
    log(checkInTime.status);
    log(checkInTime.duration.inSeconds.toString());
    log('Deleting check-in time for user: ${checkInTime.dateTime.toIso8601String()}');
    await _firestore.collection('users').doc(_user!.uid).update({
      'checkInTimes': FieldValue.arrayRemove([{
        'dateTime': checkInTime.dateTime.toIso8601String(),
        'status': checkInTime.status, // Use the status from the CheckInTime object
        'duration': checkInTime.duration.inSeconds // Use the duration from the CheckInTime object
      }])
    });

    notifyListeners();
  }
}

  void _startTimer() async {
    log('Starting timer');
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        _checkForOpenCheckInTimes();
        _checkForMissedCheckInTimes();

        // _checkForMissedCheckInTimes();
        // _checkForMissedCheckInTimesFromWatching();
        // log('Raising notification');
        // await _showNotification();
    });
  }
void _checkForOpenCheckInTimes() async {
  if (_user != null) {
    final now = DateTime.now().toUtc();
    final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final checkInTimes = (userData['checkInTimes'] as List).map((time) {
        return CheckInTime(
          dateTime: DateTime.parse(time['dateTime']),
          status: time['status'],
          duration: Duration(seconds: time['duration']),
        );
      }).toList();

      for (var checkInTime in checkInTimes) {
        if (checkInTime.dateTime.isBefore(now) && !checkInTime.dateTime.isAfter(now.add(const Duration(minutes: 5))) && checkInTime.status == 'pending') {
          log('Setting status to open for user stored checkInTime: ${checkInTime.dateTime.toString()}');
          setCheckInStatus(checkInTime.dateTime, 'open');
          notifyListeners(); // Notify listeners about the change
        }
      }
    }
  }
}
// void _checkForOpenCheckInTimes() async {
//   if (_user != null) {
//     final now = DateTime.now();
//     // Create a copy of the list to avoid concurrent modification
//     // final checkInTimesCopy = List.from(_user!.checkInTimes);
//     final checkInTimesCopy = List.from(_user!.checkInTimes.where((checkInTime) => checkInTime.status == 'pending'));

//     for (var checkInTime in checkInTimesCopy) {
//       log('Checking user stored pending only checkInTime: ${checkInTime.dateTime.toString()}');
//       if (checkInTime.dateTime.isBefore(now) && !checkInTime.dateTime.isAfter(now.add(const Duration(minutes:5))) && checkInTime.status == 'pending') {
//         log('Setting status to open for user stored checkInTime: ${checkInTime.dateTime.toString()}');
//         setCheckInStatus(checkInTime.dateTime, 'open');
//         notifyListeners(); // Notify listeners about the change
//       }
//     }
//   }
// }

void _checkForMissedCheckInTimes() async {
  if (_user != null) {
    final now = DateTime.now();
    // Create a copy of the list to avoid concurrent modification
    final checkInTimesCopy = List.from(_user!.checkInTimes);
    for (var checkInTime in checkInTimesCopy) {
      if ((checkInTime.status == 'open' || checkInTime.status == 'pending' || checkInTime.status == 'missed') && now.isAfter(checkInTime.dateTime.add(const Duration(minutes: 5)))) {
        // if (checkInTime.status != 'missed') {
        //   setCheckInStatus(checkInTime.dateTime, 'missed');
        //   DateTime newCheckInTime = checkInTime.dateTime.add(const Duration(hours: 24));
        //   addCheckInTime(newCheckInTime);
        // }
          if (navigatorKey.currentContext != null) {
          showDialog(
            barrierDismissible: false,
            context: navigatorKey.currentContext!,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Missed Check-In ${checkInTime.status}'),
                content: Text('You have missed a check-in time at ${checkInTime.dateTime.hour.toString().padLeft(2, '0')}:${checkInTime.dateTime.minute.toString().padLeft(2, '0')}.'), actions: <Widget>[ TextButton( child: const Text('OK'), onPressed: () { 
                  setCheckInStatus(checkInTime.dateTime, 'acknowledged'); 
                  addCheckInTime(checkInTime.dateTime.add(const Duration(hours: 24)));
                  Navigator.of(context).pop();
                  },
                  ),
                ],
              );
            },);
        } else {
          log('Navigator context is null, cannot show alert');
        }
      }
    }
  }
}

  // Future<void> _checkForMissedCheckInTimes() async {
  //   log('Checking for missed check-in times');
  //   final now = TimeOfDay.now();
  //   final nextPendingCheckInTime = this.nextPendingCheckInTime;
  //   log('Checking time - now: ${now.hour}:${now.minute}, nextPendingCheckInTime: ${nextPendingCheckInTime?.dateTime.hour}:${nextPendingCheckInTime?.dateTime.minute}');
  //   if (nextPendingCheckInTime != null) {
  //     if (nextPendingCheckInTime.dateTime.hour < now.hour || (nextPendingCheckInTime.dateTime.hour == now.hour && nextPendingCheckInTime.dateTime.minute < now.minute)) {
  //       setCheckInStatus(nextPendingCheckInTime.dateTime, 'missed');
  //       // await _showNotification('Missed Check-In', 'You have missed a check-in time at ${nextPendingCheckInTime.time.hour}:${nextPendingCheckInTime.time.minute}');
  //       _showAlert('You missed a Check-In!');
  //     }
  //   }
  // }
  
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

Future<void> _showAlert(String title, String watchingUid, CheckInTime checkInTime) async {
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
              onPressed: () async {
                final userDoc = await _firestore.collection('users').doc(watchingUid).get();
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  final checkInTimes = (userData['checkInTimes'] as List<dynamic>).map((e) => CheckInTime.fromMap(e)).toList();

                  for (var time in checkInTimes) {
                    if (time.dateTime == checkInTime.dateTime) {
                      time.status = 'acknowledgedByWatcher';
                      break;
                    }
                  }

                  // Update Firestore
                  await _firestore.collection('users').doc(watchingUid).update({
                    'checkInTimes': checkInTimes.map((time) => time.toMap()).toList(),
                  });
                }

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
      log('Returning future check-in time');
      return futureCheckInTimes.reduce((a, b) => a.dateTime.hour < b.dateTime.hour || (a.dateTime.hour == b.dateTime.hour && a.dateTime.minute < b.dateTime.minute) ? a : b);
    } else {
      log('Returning pending check-in time');
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

  Future<void> updateFcmToken(String token) async {
    if (_user != null) {
      _user = User(
        uid: _user!.uid,
        email: _user!.email,
        name: _user!.name,
        phoneNumber: _user!.phoneNumber,
        checkInTimes: _user!.checkInTimes,
        relatives: _user!.relatives,
        watching: _user!.watching,
        fcmToken: token,
      );
      await _firestore.collection('users').doc(_user!.uid).update({
        'fcmToken': token,
      });
      notifyListeners();
    }
  }

  Future<void> _checkForMissedCheckInTimesFromWatching() async {
    log('Checking for missed check-in times from watching ${_user?.watching.length} users');
    if (_user != null) {
      for (var watching in _user!.watching) {
        log('Checking for user $watching'); 
        final watchingUid = watching['uid'];
        if (watchingUid != null) {
          final userDoc = await _firestore.collection('users').doc(watchingUid).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final checkInTimes = (userData['checkInTimes'] as List<dynamic>).map((e) => CheckInTime.fromMap(e)).toList();

            for (var checkInTime in checkInTimes) {
              if (checkInTime.status == 'missed') {
                // Missed check-in time found
                log('User $watchingUid missed check-in time at ${checkInTime.dateTime.hour}:${checkInTime.dateTime.minute}');
                // await _showNotification('Missed Check-In', 'User $watchingUid missed a check-in time at ${checkInTime.time.hour}:${checkInTime.time.minute}');
                log('User $watchingUid missed check-in time at ${checkInTime.dateTime.hour}:${checkInTime.dateTime.minute}');
                _showAlert('User $watchingUid missed check-in time', watchingUid, checkInTime);
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
    void handleNotification(RemoteMessage message) {
    // Handle the notification and update the state
    // For example, you can fetch new data from Firestore and update the user
    _fetchUserData(_user!.uid);
  }
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
  final String? fcmToken;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.checkInTimes,
    required this.relatives,
    required this.watching,
    this.fcmToken,
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
      fcmToken: data['fcmToken'],
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
      'fcmToken': fcmToken,
    };
  }
}