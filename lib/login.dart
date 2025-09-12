import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main.dart' as mainpage;
import 'push.dart' as pushPage;
import 'adminMenu.dart' as adminMenuPage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: '', home: UserForm());
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref(
        "users",
      ); // users table

      final snapshot = await ref.get();

      if (snapshot.exists) {
        bool found = false;
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        users.forEach((key, value) {
          final user = User.fromJson(value);

          if (user.email == _emailController.text.trim() &&
              user.password == _passwordController.text.trim()) {
            found = true;

            if (user.position == "Client") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => pushPage.UserForm(userInfo: user.email),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login Client successful!')),
              );
            } else if (user.position == "Admin") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => pushPage.UserForm(userInfo: user.email),
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => adminMenuPage.MyApp()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Login Admin successful!')),
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
      print('Error during login: $e');
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
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
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
