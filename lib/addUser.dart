import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {}

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'ADD NEW USERS', home: UserForm());
  }
}

class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class User {
  final String email;
  final String fname;
  final String lname;
  final String password;
  final String position;

  User({
    required this.fname,
    required this.lname,
    required this.email,
    required this.password,
    required this.position,
  });

  factory User.fromJson(Map<dynamic, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      fname: json['fname'] ?? '',
      lname: json['lname'] ?? '',
      password: json['password'] ?? '',
      position: json['position'] ?? '',
    );
  }
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedUserType;
  bool _isLoading = false;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<bool> existingEmail() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("users");

      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        // Check if any user has the same email (username)
        for (var entry in users.entries) {
          final user = User.fromJson(entry.value);

          if (user.email.toLowerCase() ==
              _emailController.text.trim().toLowerCase()) {
            return true; // Username already exists
          }
        }
      }

      return false; // No match found
    } catch (e) {
      print('Error checking existing email: $e');
      return false; // Return false on error to allow form to proceed
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Check if username already exists
      bool emailExists = await existingEmail();

      if (emailExists) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Username Taken'),
              content: Text(
                'This username already exists. Please choose a different one.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
        return; // Stop submission
      }

      try {
        // Generate a new unique key for each user
        String userId = _database.child('users').push().key!;

        await _database.child('users').child(userId).set({
          'active': "1",
          'fname': _fnameController.text.trim(),
          'lname': _lnameController.text.trim(),
          'email': _emailController.text
              .trim(), // Still stored as 'email' in database
          'password': _passwordController.text
              .trim(), // ⚠ stored in plain text!
          'position': _selectedUserType,
          'createdAt': ServerValue.timestamp,
          'uid': userId,
        });

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Success'),
              content: Text('User saved to Realtime Database!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearForm();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Failed to save user. Please try again.'),
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
    }
  }

  void _clearForm() {
    _fnameController.clear();
    _lnameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _selectedUserType = null;
    });
  }

  bool isOnlyLettersNoSpaces(String input) {
    final RegExp regex = RegExp(r'^[a-zA-Z]+$');
    return regex.hasMatch(input);
  }

  bool isValid(String input) {
    final hasCapital = input.contains(RegExp(r'[A-Z]'));
    final hasNumber = input.contains(RegExp(r'[0-9]'));
    final noSpaces = !input.contains(' ');
    final longEnough = input.length >= 6;
    return hasCapital && hasNumber && noSpaces && longEnough;
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // go back to previous page
        return false; // prevent default behavior
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Add a User')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _fnameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (value) =>
                      value == null ||
                          value.isEmpty ||
                          !isOnlyLettersNoSpaces(value)
                      ? 'Enter first name (letters only, no spaces)'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _lnameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: (value) =>
                      value == null ||
                          value.isEmpty ||
                          !isOnlyLettersNoSpaces(value)
                      ? 'Enter last name (letters only, no spaces)'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter valid username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: '6+ chars, 1+ capital, 1+ digit, no spaces',
                    helperMaxLines: 2,
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty || !isValid(value)
                      ? 'Password must be 6+ chars with 1+ capital letter, 1+ digit, no spaces'
                      : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: InputDecoration(labelText: 'User Type'),
                  items: ['Admin', 'Client'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUserType = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a user type' : null,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
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
                            : Text('Save User', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
