import 'dart:async';
import 'dart:developer';
import 'dart:math' as mymath;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sabaidee/main.dart';
import 'package:sabaidee/models/check_in_time.dart';
import 'package:sabaidee/models/user.dart' as myUser;

class UserProvider with ChangeNotifier {
  myUser.User? _user;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timer;

  UserProvider() {
    initializeFcmTokenListener();
  }

  myUser.User? get user => _user;

  void setUser(myUser.User user) {
    _user = user;
    notifyListeners();
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
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (!userDoc.exists) {
            // Create a new user record in Firestore with placeholder values
            await _firestore.collection('users').doc(firebaseUser.uid).set({
              'email': firebaseUser.email,
              'name': firebaseUser.displayName ?? 'TBC',
              'country': {'name': 'TBC'},
              'checkInTimes': [],
              'followers': [],
              'watching': [],
              'fcmToken': 'TBC',
              'referralCode': _generateRandomCode(),
              'emojisEnabled': true, // Default to true
              'quotesEnabled': true, // Default to true
              'locationSharingEnabled': false, // Default to false
            });
          }

          // Fetch user data from Firestore
          await fetchUserData(firebaseUser.uid);
        }
      }
    } catch (error) {
      print('Google sign-in failed: $error');
    }
  }

  Future<void> fetchUserData(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      log('User data from Firestore: ${userDoc.data()}, uid provided: $uid');
      _user = myUser.User.fromFirestore(userDoc);
      notifyListeners();
    } else {
      log('User document does not exist for UID: $uid');
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = mymath.Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> addCheckInTime(DateTime dateTime) async {
    if (_user != null) {
      final checkInTime = CheckInTime(
        dateTime: dateTime,
        status: 'pending',
        duration: const Duration(minutes: 30), // Set default duration to 30 minutes
        emoji: null, // Initialize emoji as null
      );
      log('Adding check-in time for user: ${checkInTime.dateTime.toIso8601String()}');
      _user!.checkInTimes.add(checkInTime);

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'checkInTimes': FieldValue.arrayUnion([
          {
            'dateTime': checkInTime.dateTime.toIso8601String(),
            'status': 'pending',
            'duration': checkInTime.duration.inMinutes,
            'emoji': checkInTime.emoji, // Add emoji field
          }
        ])
      });

      notifyListeners();
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
      notifyListeners();
    }
  }

  void setCheckInStatus(DateTime dateTime, String status, {String? emoji}) async {
    if (_user != null) {
      for (var checkInTime in _user!.checkInTimes) {
        if (checkInTime.dateTime == dateTime) {
          checkInTime.status = status;
          if (emoji != null) {
            checkInTime.emoji = emoji; // Update the emoji field if provided
          }
          break;
        }
      }

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'checkInTimes': _user!.checkInTimes.map((checkInTime) => checkInTime.toMap()).toList(),
      });

      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final fcmToken = await FirebaseMessaging.instance.getToken();

      _user = myUser.User(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        country: {'name': 'Test Country'},
        checkInTimes: [],
        followers: [],
        watching: [],
        fcmToken: fcmToken,
        referralCode: _generateRandomCode(),
        emojisEnabled: true, // Default to true
        quotesEnabled: true, // Default to true
        locationSharingEnabled: false, // Default to false
        address: '', // Add empty address
        phoneNumber: '', // Add empty phone number
      );

      // Add user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'country': {'name': 'Test Country'},
        'checkInTimes': [],
        'followers': [],
        'watching': [],
        'fcmToken': fcmToken,
        'referralCode': _generateRandomCode(),
        'emojisEnabled': true, // Default to true
        'quotesEnabled': true, // Default to true
        'locationSharingEnabled': false, // Default to false
        'address': '', // Add empty address
        'phoneNumber': '', // Add empty phone number
      });

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserData(userCredential.user!.uid);
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
        final createdAt = watching['createdAt'];
        final userDoc = await _firestore.collection('users').doc(watchingUid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          watchingNamesAndStatuses[watchingUid!] = {
            'name': userData['name'],
            'status': status!,
            'createdAt': createdAt!,
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
    _user = myUser.User.fromFirestore(userDoc);
    notifyListeners();
  }

  List<CheckInTime> get scheduleTimes {
    return _user?.checkInTimes ?? [];
  }

  List<CheckInTime> get pendingOrOpenCheckInTimes {
    return _user?.checkInTimes.where((time) => time.status == 'pending' || time.status == 'open').toList() ?? [];
  }

  Future<void> deleteAccountAndData() async {
    if (_user != null) {
      try {
        // Delete user authentication
        await FirebaseAuth.instance.currentUser!.delete();

        // Delete user data from Firestore
        await _firestore.collection('users').doc(_user!.uid).delete();

        // Sign out the user
        await signOut();
      } catch (e) {
        print('Failed to delete account and data: $e');
        throw Exception('Failed to delete account and data: $e');
      }
    }
  }

  Future<void> deleteCheckInTime(CheckInTime checkInTime) async {
    if (_user != null) {
      // Log the object being removed
      final checkInTimeToRemove = {
        'dateTime': checkInTime.dateTime.toIso8601String(),
        'status': checkInTime.status,
        'duration': checkInTime.duration.inMinutes,
        'emoji': null, // Set emoji to null for deletion
        // if (checkInTime.emoji != null) 'emoji': checkInTime.emoji, // Include emoji if it exists
      };

      log('Attempting to delete check-in time: $checkInTimeToRemove');

      // Remove the check-in time from the local list
      _user!.checkInTimes.removeWhere((existingCheckInTime) => existingCheckInTime.dateTime == checkInTime.dateTime);

      // Update Firestore
      try {
        await _firestore.collection('users').doc(_user!.uid).update({
          'checkInTimes': FieldValue.arrayRemove([checkInTimeToRemove]),
        });
        log('Successfully deleted check-in time from Firestore: $checkInTimeToRemove');
      } catch (e) {
        log('Failed to delete check-in time from Firestore: $e');
      }

      notifyListeners();
    }
  }

  void _startTimer() async {
    log('Starting timer');
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      _checkForOpenCheckInTimes();
      _checkForMissedCheckInTimes();
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
            duration: Duration(minutes: time['duration']), // Parse duration from minutes
          );
        }).toList();

        for (var checkInTime in checkInTimes) {
          if (checkInTime.dateTime.isBefore(now) && !checkInTime.dateTime.isAfter(now.add(Duration(minutes: checkInTime.duration.inMinutes))) && checkInTime.status == 'pending') {
            log('Setting status to open for user stored checkInTime: ${checkInTime.dateTime.toString()}');
            setCheckInStatus(checkInTime.dateTime, 'open');
            notifyListeners(); // Notify listeners about the change
          }
        }
      }
    }
  }

  void _checkForMissedCheckInTimes() async {
    if (_user != null) {
      final now = DateTime.now();
      // Create a copy of the list to avoid concurrent modification
      final checkInTimesCopy = List.from(_user!.checkInTimes);
      log('Missed Check In');
      for (var checkInTime in checkInTimesCopy) {
        if ((checkInTime.status == 'open' || checkInTime.status == 'pending' || checkInTime.status == 'missed') && now.isAfter(checkInTime.dateTime.add(const Duration(minutes: 5)))) {
          if (navigatorKey.currentContext != null) {
            showDialog(
              barrierDismissible: false,
              context: navigatorKey.currentContext!,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Missed Check-In ${checkInTime.status}'),
                  content: Text('You have missed a check-in time at ${checkInTime.dateTime.hour.toString().padLeft(2, '0')}:${checkInTime.dateTime.minute.toString().padLeft(2, '0')}.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        setCheckInStatus(checkInTime.dateTime, 'acknowledged');
                        addCheckInTime(checkInTime.dateTime.add(const Duration(hours: 24)));
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
      }
    }
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

  List<Map<String, String>> get followers {
    return _user?.followers ?? [];
  }

  Future<void> removeFollower(String uid) async {
    _user?.followers.removeWhere((follower) => follower['uid'] == uid);
    // Update Firestore for the current user
    await _firestore.collection('users').doc(_user!.uid).update({
      'followers': FieldValue.arrayRemove([
        {'uid': uid, 'status': 'pending'}
      ]),
    });

    // Update Firestore for the follower user
    await _firestore.collection('users').doc(uid).update({
      'followers': FieldValue.arrayRemove([
        {'uid': _user!.uid, 'status': 'pending'}
      ]),
    });
    // Update Firestore for the watcher user
    await _firestore.collection('users').doc(uid).update({
      'watching': FieldValue.arrayRemove([
        {'uid': _user!.uid, 'status': 'pending'}
      ]),
    });

    notifyListeners();
  }

  Future<void> updateUser({
    required String name,
    required Map<String, String> country,
    String? address, // Add address as an optional parameter
    String? phoneNumber, // Add phone number as an optional parameter
    bool? emojisEnabled,
    bool? quotesEnabled,
    bool? locationSharingEnabled, // Add locationSharingEnabled as an optional parameter
  }) async {
    if (_user == null) return;

    // Update the user information in the provider
    _user?.name = name;
    _user?.country = country;
    if (address != null) {
      _user?.address = address;
    }
    if (phoneNumber != null) {
      _user?.phoneNumber = phoneNumber;
    }
    if (emojisEnabled != null) {
      _user?.emojisEnabled = emojisEnabled;
    }
    if (quotesEnabled != null) {
      _user?.quotesEnabled = quotesEnabled;
    }
    if (locationSharingEnabled != null) {
      _user?.locationSharingEnabled = locationSharingEnabled;
    }
    notifyListeners();

    // Update the user information in Firestore
    await FirebaseFirestore.instance.collection('users').doc(_user?.uid).update({
      'name': name,
      'country': country,
      if (address != null) 'address': address, // Update address if provided
      if (phoneNumber != null) 'phoneNumber': phoneNumber, // Update phone number if provided
      if (emojisEnabled != null) 'emojisEnabled': emojisEnabled,
      if (quotesEnabled != null) 'quotesEnabled': quotesEnabled,
      if (locationSharingEnabled != null) 'locationSharingEnabled': locationSharingEnabled, // Update locationSharingEnabled if provided
    });
  }

  Future<void> removeRelationship(String followerUid, String status) async {
    log('Removing relationship for user: ${_user?.uid} with followerUid: $followerUid');
    if (_user != null) {
      // Find the relationship entry with the matching followerUid and status
      final relationship = _user!.watching.firstWhere(
        (watching) => watching['uid'] == followerUid && watching['status'] == status,
        orElse: () => {},
      );

      await _firestore.collection('users').doc(_user!.uid).update({
        'watching': FieldValue.arrayRemove([relationship]),
      });

      // Remove the follower entry from the other user
      final followerDoc = await _firestore.collection('users').doc(followerUid).get();
      if (followerDoc.exists) {
        final followerData = followerDoc.data();
        final followerRelationship = (followerData?['followers'] as List<dynamic>).firstWhere(
          (follower) => follower['uid'] == _user!.uid && follower['status'] == status,
          orElse: () => null,
        );

        if (followerRelationship != null) {
          log('Removing relationship for user: $followerUid with followerUid: ${_user?.uid}');
          await _firestore.collection('users').doc(followerUid).update({
            'followers': FieldValue.arrayRemove([followerRelationship]),
          });
        } else {
          log('No relationship found for user: $followerUid with followerUid: ${_user?.uid}');
        }
      }
      // Remove the relationship from the provider _user
      _user!.watching.removeWhere((watching) => watching['uid'] == followerUid && watching['status'] == status);

      notifyListeners();
    }
  }

  Future<void> createRelationship(String followerUid, String status) async {
    if (_user != null) {
      _user!.watching.add({'uid': followerUid, 'status': status, 'createdAt': DateTime.now().toIso8601String()});

      // Update Firestore for the current user
      await _firestore.collection('users').doc(_user!.uid).update({
        'watching': FieldValue.arrayUnion([{'uid': followerUid, 'status': status, 'createdAt': DateTime.now().toIso8601String()}]),
      });

      // Update Firestore for the follower user
      await _firestore.collection('users').doc(followerUid).update({
        'followers': FieldValue.arrayUnion([{'uid': _user!.uid, 'status': status, 'createdAt': DateTime.now().toIso8601String()}]),
      });

      notifyListeners();
    }
  }

  Future<void> updateFcmToken(String uid, String token) async {
    if (_user != null) {
      _user = myUser.User(
        uid: _user!.uid,
        email: _user!.email,
        name: _user!.name,
        country: _user!.country,
        checkInTimes: _user!.checkInTimes,
        followers: _user!.followers,
        watching: _user!.watching,
        fcmToken: token,
        referralCode: _user!.referralCode,
        emojisEnabled: _user!.emojisEnabled, // Add the required parameter
        quotesEnabled: _user!.quotesEnabled, // Add the required parameter
        locationSharingEnabled: _user!.locationSharingEnabled, // Add the required parameter
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
                _showAlert('User $watchingUid missed check-in time', watchingUid, checkInTime);
              }
            }
          }
        }
      }
    }
  }

  void handleNotification(RemoteMessage message) {
    // Handle the notification and update the state
    // For example, you can fetch new data from Firestore and update the user
    _fetchUserData(_user!.uid);
  }

  Future<void> toggleLocationSharing(bool enabled) async {
    if (_user != null) {
      _user!.locationSharingEnabled = enabled;

      // Update Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'locationSharingEnabled': enabled,
      });

      notifyListeners();
    }
  }

  void initializeFcmTokenListener() async {
    // Get the initial FCM token
    final String? initialToken = await FirebaseMessaging.instance.getToken();
    if (initialToken != null) {
      await updateFcmToken(_user!.uid, initialToken);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      log('FCM token refreshed: $newToken');
      await updateFcmToken(_user!.uid, newToken);
    }).onError((error) {
      log('Error refreshing FCM token: $error');
    });
  }
}

