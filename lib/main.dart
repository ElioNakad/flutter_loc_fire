import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully!");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

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

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedUserType;
  bool _isLoading = false;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Generate a new unique key for each user
        String userId = _database.child('users').push().key!;

        await _database.child('users').child(userId).set({
          'fname': _fnameController.text.trim(),
          'lname': _lnameController.text.trim(),
          'email': _emailController.text.trim(),
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
        print("Error saving user: $e");

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
    return Scaffold(
      appBar: AppBar(title: Text('ADD a new user')),
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
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty || !value.contains('@')
                    ? 'Enter valid email'
                    : null,
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
    );
  }
}
