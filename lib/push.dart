import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String? userInfo; // Make it optional with ?

  const MyApp({Key? key, this.userInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      home: UserForm(userInfo: userInfo),
    );
  }
}

class UserForm extends StatefulWidget {
  final String? userInfo; // Make it optional

  const UserForm({Key? key, this.userInfo}) : super(key: key);

  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  bool _isLoading = false;

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

  Future<String> getCurrentLocationString() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permissions are permanently denied.';
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Return as "latitude,longitude"
      return '${position.latitude},${position.longitude}';
    } catch (e) {
      return 'Error getting location: $e';
    }
  }

  String getTodayDateTime() {
    final now = DateTime.now();

    // Format: YYYY-MM-DD HH:MM:SS
    String formatted =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    return formatted;
  }

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String location = 'unknown';
      String deviceId = 'unknown';

      try {
        location = await getCurrentLocationString();
      } catch (e) {
        print("Location error: $e");
      }

      try {
        deviceId = await getDeviceId();
      } catch (e) {
        print("Device ID error: $e");
      }

      String userId = _database.child('pushed').push().key!;

      if (location == "unknown" ||
          location == "Location services are disabled." ||
          location == "Location permissions are denied" ||
          location == "Location permissions are permanently denied.") {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('failed'),
            content: Text('Make sure your device location is turned on'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        await _database.child('pushed').child(userId).set({
          'email': widget.userInfo ?? 'no-email',
          'location': location,
          'deviceId': deviceId,
          'date': getTodayDateTime(),
          'createdAt': ServerValue.timestamp,
          'uid': userId,
        });

        if (!mounted) return;
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Success'),
            content: Text('Data saved to Realtime Database!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error saving user: $e");

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to save data. Please try again.'),
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
    return Scaffold(
      appBar: AppBar(title: Text('push page')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Vertically center
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Horizontally center
              children: [
                ElevatedButton(onPressed: _submitForm, child: Text('Push')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
