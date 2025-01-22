import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class MyRelativesPage extends StatelessWidget {
  const MyRelativesPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchRegisteredUsers(String currentUserUid) async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    return usersSnapshot.docs
        .map((doc) => {
              'uid': doc.id,
              ...doc.data(),
            })
        .where((user) => user['uid'] != currentUserUid) // Filter out the current user
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final relatives = userProvider.relatives;
    final currentUserUid = userProvider.user?.uid;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('My Relatives'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.yellow,
      ),
      body: ListView.builder(
        itemCount: relatives.length,
        itemBuilder: (context, index) {
          final relativeUid = relatives[index];
          return ListTile(
            title: Text('Relative UID: $relativeUid'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Handle delete relative
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (currentUserUid != null) {
            final registeredUsers = await _fetchRegisteredUsers(currentUserUid);
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Add Relative'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: registeredUsers.length,
                      itemBuilder: (context, index) {
                        final user = registeredUsers[index];
                        return ListTile(
                          title: Text(user['email']),
                          onTap: () {
                            userProvider.addRelative(user['uid']);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}