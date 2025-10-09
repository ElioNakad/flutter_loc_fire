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
    return MaterialApp(
      title: 'ADD NEW USERS',
      theme: ThemeData(
        primaryColor: Color(0xFF003D5C),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF003D5C),
          secondary: Color(0xFFFF6B5A),
        ),
      ),
      home: UserForm(),
    );
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
  bool _obscurePassword = true;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<bool> existingEmail() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("users");

      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in users.entries) {
          final user = User.fromJson(entry.value);

          if (user.email.toLowerCase() ==
              _emailController.text.trim().toLowerCase()) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking existing email: $e');
      return false;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      bool emailExists = await existingEmail();

      if (emailExists) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text('Username Taken'),
                ],
              ),
              content: Text(
                'This username already exists. Please choose a different one.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFFFF6B5A),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      try {
        String userId = _database.child('users').push().key!;

        await _database.child('users').child(userId).set({
          'active': "1",
          'fname': _fnameController.text.trim(),
          'lname': _lnameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Success'),
                ],
              ),
              content: Text(
                'User saved to Realtime Database!',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearForm();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFFFF6B5A),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('Error'),
                ],
              ),
              content: Text(
                'Failed to save user. Please try again.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFFFF6B5A),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: TextStyle(fontSize: 12),
          prefixIcon: Icon(icon, color: Color(0xFF003D5C)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Add a User',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF003D5C),
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B5A), Color(0xFFFF8A7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New User Registration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Fill in the details below',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Form Fields
                _buildTextField(
                  controller: _fnameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value == null ||
                          value.isEmpty ||
                          !isOnlyLettersNoSpaces(value)
                      ? 'Enter first name (letters only, no spaces)'
                      : null,
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _lnameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value == null ||
                          value.isEmpty ||
                          !isOnlyLettersNoSpaces(value)
                      ? 'Enter last name (letters only, no spaces)'
                      : null,
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Username',
                  icon: Icons.account_circle_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter valid username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  helperText: '6+ chars, 1+ capital, 1+ digit, no spaces',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty || !isValid(value)
                      ? 'Password must be 6+ chars with 1+ capital letter, 1+ digit, no spaces'
                      : null,
                ),
                SizedBox(height: 16),

                // Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF003D5C),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
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
                ),
                SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B5A), Color(0xFFFF8A7A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF6B5A).withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save User',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
