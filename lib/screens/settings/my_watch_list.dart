import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sabaidee/user_provider.dart';

class MyWatchList extends StatelessWidget {
  const MyWatchList({super.key});

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
    final watchings = userProvider.watching;
    final currentUserUid = userProvider.user?.uid;

    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: const Text('My WatchList'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.yellow,
      ),
           body: FutureBuilder<Map<String, Map<String, String>>>(
        future: userProvider.fetchWatchingNamesAndStatuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No watching list found'));
          } else {
            final watchingNamesAndStatuses = snapshot.data!;
            return ListView.builder(
              itemCount: watchings.length,
              itemBuilder: (context, index) {
                final watching = watchings[index];
                final watchingUid = watching['uid'];
                final watchingName = watchingNamesAndStatuses[watchingUid]?['name'] ?? 'Unknown';
                final watchingStatus = watchingNamesAndStatuses[watchingUid]?['status'] ?? 'Unknown';
                return ListTile(
                  title: Text('Name: $watchingName'),
                  subtitle: Text('Status: $watchingStatus'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      // Handle delete relative
                    },
                  ),
                );
              },
            );
          }
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
                          title: Text(user['name']),
                          onTap: () {
                            userProvider.addRelative(user['uid'],'pending');
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