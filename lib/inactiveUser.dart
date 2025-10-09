import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Active/Inactive', home: ActiveInactiveForm());
  }
}

class ActiveInactiveForm extends StatefulWidget {
  @override
  _ActiveInactiveFormState createState() => _ActiveInactiveFormState();
}

class _ActiveInactiveFormState extends State<ActiveInactiveForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    fetchUsers();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final email = user['email']?.toString().toLowerCase() ?? '';
          return email.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _toggleActiveStatus() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final snapshot = await _database.child('users').get();

        if (snapshot.exists) {
          Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

          String? foundUserId;
          String? foundUserName;
          String? currentActive;

          users.forEach((key, value) {
            if (value['email'] == _emailController.text.trim()) {
              foundUserId = key;
              foundUserName = '${value['fname']} ${value['lname']}';
              currentActive = value['active']?.toString() ?? "0";
            }
          });

          if (foundUserId != null) {
            String newActive = currentActive == "1" ? "0" : "1";

            await _database.child('users').child(foundUserId!).update({
              'active': newActive,
            });

            setState(() {
              _isLoading = false;
            });

            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Success'),
                  content: Text(
                    'Status updated successfully for $foundUserName!\nNew status: ${newActive == "1" ? 'Active' : 'Inactive'}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearForm();
                        fetchUsers(); // Refresh the list
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
          } else {
            setState(() {
              _isLoading = false;
            });
            _showDialog('Error', 'No user found with this email');
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          _showDialog('Error', 'No users found in database');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Error details: $e');
        _showDialog('Error', 'Failed to update status: ${e.toString()}');
      }
    }
  }

  void _showDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _clearForm() {
    _emailController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _usersRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> usersList = [];

        data.forEach((key, value) {
          final user = Map<String, dynamic>.from(value as Map);
          usersList.add(user);
        });

        setState(() {
          users = usersList;
          filteredUsers = usersList;
          _isLoading = false;
        });
      } else {
        setState(() {
          users = [];
          filteredUsers = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Active/Inactive Toggle')),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          hintText: 'Enter Username',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter the Username'
                            : null,
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _toggleActiveStatus,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Toggle Status',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Username',
                  hintText: 'Type to search...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // User list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No users found'
                            : 'No matching users found',
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Username: ${user['email'] ?? 'N/A'}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Active: ${user['active'] ?? 'N/A'}',
                                  style: TextStyle(
                                    color: user['active'] == "1"
                                        ? Colors.green
                                        : user['active'] == "0"
                                        ? Colors.red
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
