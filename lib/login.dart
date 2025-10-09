import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'addUser.dart' as mainpage;
import 'push.dart' as pushPage;
import 'adminMenu.dart' as adminMenuPage;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class User {
  final String active;
  final String email;
  final String fname;
  final String lname;
  final String password;
  final String position;

  User({
    required this.active,
    required this.fname,
    required this.lname,
    required this.email,
    required this.password,
    required this.position,
  });

  factory User.fromJson(Map<dynamic, dynamic> json) {
    return User(
      active: json['active'] ?? '',
      fname: json['fname'] ?? '',
      lname: json['lname'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      position: json['position'] ?? '',
    );
  }
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    checkDeviceAndAutoFill();
  }

  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      print('Error getting device ID: $e');
    }
    return 'unknown';
  }

  Future<void> checkDeviceAndAutoFill() async {
    try {
      String deviceId = await getDeviceId();
      DatabaseReference ref = FirebaseDatabase.instance.ref("ids");

      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> ids = snapshot.value as Map<dynamic, dynamic>;

        bool deviceFound = false;
        ids.forEach((key, value) {
          if (value['device'] == deviceId) {
            deviceFound = true;
            setState(() {
              _emailController.text = value['email'] ?? '';
              _passwordController.text = value['password'] ?? '';
            });
          }
        });

        if (!deviceFound) {
          print('Device not found in database');
        }
      }
    } catch (e) {
      print('Error checking device ID: $e');
    }
  }

  Future<void> saveInIds() async {
    try {
      String deviceId = await getDeviceId();
      DatabaseReference ref = FirebaseDatabase.instance.ref("ids");

      final snapshot = await ref.get();
      bool deviceExists = false;
      String? existingKey;

      if (snapshot.exists) {
        Map<dynamic, dynamic> ids = snapshot.value as Map<dynamic, dynamic>;

        ids.forEach((key, value) {
          if (value['device'] == deviceId) {
            deviceExists = true;
            existingKey = key;

            if (value['email'] != _emailController.text) {
              ref.child(key).set({
                'device': deviceId,
                'email': _emailController.text,
                'password': _passwordController.text,
              });
              print('Device credentials updated successfully');
            }
          }
        });
      }

      if (!deviceExists) {
        await ref.push().set({
          'device': deviceId,
          'email': _emailController.text,
          'password': _passwordController.text,
        });
        print('Device ID saved successfully');
      }
    } catch (e) {
      print('Error saving device ID: $e');
    }
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("users");

      final snapshot = await ref.get();

      if (snapshot.exists) {
        bool found = false;
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        users.forEach((key, value) {
          final user = User.fromJson(value);

          if (user.email == _emailController.text.trim() &&
              user.password == _passwordController.text.trim()) {
            found = true;

            if (user.active == '1') {
              saveInIds();

              if (user.position == "Client") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        pushPage.UserForm(userInfo: user.email),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login Client successful!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (user.position == "Admin") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => adminMenuPage.Menu()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login Admin successful!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('This user has been inactivated!'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        });

        if (!found) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid email or password'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No users found in database'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database error. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icon Section
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B5A).withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 80,
                        color: Color(0xFFFF6B5A),
                      ),
                    ),
                    SizedBox(height: 32),

                    // Title
                    Text(
                      'ONLINE PUNCHING',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D5C),
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'MACHINE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003D5C),
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Welcome back',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 48),

                    // Username Field
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
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(
                            Icons.person_outline,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Username';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password Field
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
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Color(0xFF003D5C),
                          ),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 32),

                    // Login Button
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
                        onPressed: _isLoading ? null : loginUser,
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
                            : Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
