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
    return MaterialApp(title: 'UPDATE PASSWORD', home: PasswordUpdateForm());
  }
}

class PasswordUpdateForm extends StatefulWidget {
  @override
  _PasswordUpdateFormState createState() => _PasswordUpdateFormState();
}

class _PasswordUpdateFormState extends State<PasswordUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> _updatePassword() async {
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

          users.forEach((key, value) {
            if (value['email'] == _emailController.text.trim()) {
              foundUserId = key;
              foundUserName = '${value['fname']} ${value['lname']}';
            }
          });

          if (foundUserId != null) {
            // User found, update password
            await _database.child('users').child(foundUserId.toString()).update(
              {'password': _passwordController.text.trim()},
            );

            setState(() {
              _isLoading = false;
            });

            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Success'),
                  content: Text(
                    'Password updated successfully for $foundUserName!',
                  ),
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
          } else {
            // User not found
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
        _showDialog('Error', 'Failed to update password. Please try again.');
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
    _passwordController.clear();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Update Password')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Username'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter valid Username'
                      : null,
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    helperText: '6+ chars, 1+ capital, 1+ digit, no spaces',
                    helperMaxLines: 2,
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty || !isValid(value)
                      ? 'Password must be 6+ chars with 1+ capital letter, 1+ digit, no spaces'
                      : null,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePassword,
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
                                'Update Password',
                                style: TextStyle(fontSize: 16),
                              ),
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
