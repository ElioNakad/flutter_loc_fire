///main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login.dart' as login;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class Ids {
  final String device;

  Ids({required this.device});

  factory Ids.fromJson(Map<dynamic, dynamic> json) {
    return Ids(device: json['device'] ?? '');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      home: LoginScreen(), // Separate the login logic into its own widget
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passController = TextEditingController();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String correctCode = "";
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkDeviceLogin();
    fillCorrectCode();
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

  Future<void> checkDeviceLogin() async {
    try {
      String id = await getDeviceId();
      DatabaseReference ref = FirebaseDatabase.instance.ref("ids");

      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> pushed = snapshot.value as Map<dynamic, dynamic>;

        bool deviceFound = false;
        pushed.forEach((key, value) {
          final user = Ids.fromJson(value);
          if (user.device == id) {
            deviceFound = true;
          }
        });

        if (mounted) {
          setState(() {
            isLoggedIn = deviceFound;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fillCorrectCode() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("Passcode/code");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        setState(() {
          correctCode = snapshot.value.toString();
        });
      }
    } catch (e) {
      print('Error fetching correct code: $e');
    }
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login.UserForm()),
    );
  }

  Future<void> compareToCorrect(String s) async {
    if (s == correctCode) {
      // Save the device ID to Firebase

      /*save id to firebase
      try {
        String id = await getDeviceId();
        DatabaseReference ref = FirebaseDatabase.instance.ref("ids");

        // Push a new entry with the device ID
        await ref.push().set({'device': id});
      } catch (e) {
        print('Error saving device ID: $e');
      }*/

      goToLogin();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Incorrect code'),
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

  @override
  Widget build(BuildContext context) {
    // If still loading, show loading indicator
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If device is already logged in, go directly to UserForm
    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        goToLogin();
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show login form
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _passController,
              decoration: InputDecoration(labelText: 'required code'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the required code';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => compareToCorrect(_passController.text),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }
}
