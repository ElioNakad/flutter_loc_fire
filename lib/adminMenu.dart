import 'package:flutter/material.dart';
import 'main.dart' as mainpage;
import 'displayClient.dart' as displayClientPage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Firebase Form', home: Menu());
  }
}

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
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
}

class _MenuState extends State<Menu> {
  List<User> userList = [];

  void goToDisplayAdmins(BuildContext context) {
    /* Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => displayAdminPage.MyApp()),
    );*/
  }

  void goToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => mainpage.MyApp()),
    );
  }

  void goToDisplayClients(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => displayClientPage.MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Menu')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    goToDisplayAdmins(context);
                  },
                  child: Text("Display all Admins"),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    goToSignUp(context);
                  },
                  child: Text("SignUp a new User"),
                ),
              ),
              SizedBox(height: 16),

              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    goToDisplayClients(context);
                  },
                  child: Text("Display all Clientss"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
