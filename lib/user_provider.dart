import 'dart:async';
import 'dart:developer';
import 'dart:math' as mymath;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
              'followers': [],
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
        'duration': checkInTime.duration.inMinutes, // Ensure duration is included
      }).toList(),
    });
    notifyListeners();
  }
}

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = mymath.Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> signUp(String email, String password, String name, String phoneNumber, Map<String, String> country) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      _user = User(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        country: country,
        checkInTimes: [],
        followers: [],
        watching: [],
        referralCode: _generateRandomCode(),
      );

      // Add user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'country': country,
        'checkInTimes': [],
        'followers': [],
        'watching': [],
        'referralCode': _generateRandomCode(),
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> fetchUserData(String uid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    _user = User.fromFirestore(userDoc);
    notifyListeners();
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

  Future<Map<String, String>> fetchFollowerEmails() async {
    final Map<String, String> followerEmails = {};
    if (_user != null) {
      for (Map<String, String> follower in _user!.followers) {
        String followerUid = follower['uid']!;
        final userDoc = await _firestore.collection('users').doc(followerUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          followerEmails[followerUid] = userData['email'];
        }
      }
    }
    return followerEmails;
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
    log('Number of watching names and statuses: ${watchingNamesAndStatuses.length}');
    return watchingNamesAndStatuses;
  }
  Future<Map<String, Map<String, String>>> fetchFollowerNamesAndStatuses() async {
    final Map<String, Map<String, String>> followerNamesAndStatuses = {};
    if (_user != null) {
      for (var follower in _user!.followers) {
        final followerUid = follower['uid'];
        final status = follower['status'];
        final userDoc = await _firestore.collection('users').doc(followerUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          followerNamesAndStatuses[followerUid!] = {
            'name': userData['name'],
            'status': status!,
          };
        }
      }
    }
    return followerNamesAndStatuses;
  }

Future<void> _fetchUserData(String uid) async {
  // Fetch user data from your database and set the _user object
  DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
  // final now = DateTime.now();
  _user = User(
    uid: uid,
    email: userDoc['email'],
    name: userDoc['name'],
    phoneNumber: userDoc['phoneNumber'],
    country: userDoc['country'] is String ? {'name': userDoc['country']} : Map<String, String>.from(userDoc['country']),
    checkInTimes: (userDoc['checkInTimes'] as List).map((time) {
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
    fcmToken: userDoc['fcmToken'],
    referralCode: userDoc['referralCode'],
    followers: (userDoc['followers'] as List).map((follower) => Map<String, String>.from(follower)).toList(),
    watching: (userDoc['watching'] as List).map((watching) => Map<String, String>.from(watching)).toList(),
    // followers: List<Map<String, String>>.from(userDoc['followers'] ?? []),
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
    log('Missed Check In');
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
  
  // Future<void> _showNotification(title, description) async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
  //     'missed_check_in_channel',
  //     'Missed Check-In',
  //     channelDescription: 'Generic notification for missed check-in times',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     ticker: 'ticker',
  //   );
  //   const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );
  //   const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //     iOS: iosPlatformChannelSpecifics,
  //   );
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     title,
  //     description,
  //     platformChannelSpecifics,
  //     payload: 'missed_check_in',
  //   );
  // }

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
  List<Map<String, String>> get followers {
    return _user?.followers ?? [];
  }
  
  Future<void> removeFollower(String uid) async {
    _user?.followers.removeWhere((follower) => follower['uid'] == uid);
          // Update Firestore for the current user
      await _firestore.collection('users').doc(_user!.uid).update({
        'followers': FieldValue.arrayRemove([{'uid': uid, 'status': 'pending'}]),
      });

    // Update Firestore for the follower user
    await _firestore.collection('users').doc(uid).update({
      'followers': FieldValue.arrayRemove([{'uid': _user!.uid, 'status': 'pending'}]),
    });
    // Update Firestore for the watcher user
    await _firestore.collection('users').doc(uid).update({
      'watching': FieldValue.arrayRemove([{'uid': _user!.uid, 'status': 'pending'}]),
    });

    notifyListeners();
  }
  // Add the updateUser method
  Future<void> updateUser({required String name, required String phoneNumber, required Map<String, String> country}) async {
    if (_user == null) return;

    // Update the user information in the provider
    _user?.name = name;
    _user?.phoneNumber = phoneNumber;
    _user?.country = country;
    notifyListeners();

    // Update the user information in the database
    await FirebaseFirestore.instance.collection('users').doc(_user?.uid).update({
      'name': name,
      'phoneNumber': phoneNumber,
    });
  }
  Future<void> createRelationship(String followerUid, String status) async {
    if (_user != null) {
      _user!.watching.add({'uid': followerUid, 'status': status});

      // Update Firestore for the current user
      await _firestore.collection('users').doc(_user!.uid).update({
        'watching': FieldValue.arrayUnion([{'uid': followerUid, 'status': status}]),
      });

      // Update Firestore for the follower user
      await _firestore.collection('users').doc(followerUid).update({
        'followers': FieldValue.arrayUnion([{'uid': _user!.uid, 'status': status}]),
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
        country: _user!.country,
        checkInTimes: _user!.checkInTimes,
        followers: _user!.followers,
        watching: _user!.watching,
        fcmToken: token,
        referralCode: _user!.referralCode,
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
  // notifyListeners();
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
  String name;
  String phoneNumber;
  Map<String, String> country; // Change country to a map with timezone
  final List<CheckInTime> checkInTimes;
  final List<Map<String, String>> followers;
  final List<Map<String, String>> watching;
  final String? fcmToken;
  final String referralCode;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.country,
    required this.checkInTimes,
    required this.followers,
    required this.watching,
    this.fcmToken,
    required this.referralCode,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      phoneNumber: data['phoneNumber'],
      country: Map<String, String>.from(data['country']),
      checkInTimes: (data['checkInTimes'] as List)
          .map((item) => CheckInTime.fromMap(item as Map<String, dynamic>))
          .toList(),
      followers: List<Map<String, String>>.from(data['followers']),
      watching: List<Map<String, String>>.from(data['watching']),
      fcmToken: data['fcmToken'],
      referralCode: data['referralCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'country': country,
      'checkInTimes': checkInTimes.map((checkInTime) => checkInTime.toMap()).toList(),
      'followers': followers,
      'watching': watching,
      'fcmToken': fcmToken,
      'referralCode': referralCode,
    };
  }
}