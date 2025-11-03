//login.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'addUser.dart' as mainpage;
import 'push.dart' as pushPage;
import 'adminMenu.dart' as adminMenuPage;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    checkDeviceAndAutoFill();
  }

  Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('unique_device_id');

      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await prefs.setString('unique_device_id', deviceId);
      }

      return deviceId;
    } catch (e) {
      print('Error with device ID: $e');
      // Fallback: generate temporary ID (won't persist, but app won't crash)
      return 'temp_${DateTime.now().millisecondsSinceEpoch}';
    }
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
            // Auto-fill the email and password fields
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

        // Check if device already exists and get its key
        ids.forEach((key, value) {
          if (value['device'] == deviceId) {
            deviceExists = true;
            existingKey = key;

            // Check if email is different, then update
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

      // Only save if device doesn't exist
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
              // Save device ID after successful login
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
                  SnackBar(content: Text('Login Client successful!')),
                );
              } else if (user.position == "Admin") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => adminMenuPage.Menu()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login Admin successful!')),
                );
              }
              // _passwordController.text = " ";
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('This user has been inactivated!')),
              );
            }
          }
        });

        if (!found) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid email or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No users found in database'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : loginUser,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Login'),
              ),
            ],
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
