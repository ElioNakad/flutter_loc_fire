import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> adminUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdminUsers();
  }

  Future<void> fetchAdminUsers() async {
    try {
      final snapshot = await _usersRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> admins = [];

        data.forEach((key, value) {
          final user = Map<String, dynamic>.from(value as Map);
          if (user['position'] == 'Admin') {
            admins.add(user);
          }
        });

        setState(() {
          adminUsers = admins;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // go back to previous page
        return false; // prevent default behavior
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin Users')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : adminUsers.isEmpty
            ? const Center(child: Text('No admin users found'))
            : ListView.builder(
                itemCount: adminUsers.length,
                itemBuilder: (context, index) {
                  final user = adminUsers[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user['email'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('First Name: ${user['fname'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Last Name: ${user['lname'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Text('Position: ${user['position'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
