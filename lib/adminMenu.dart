import 'package:flutter/material.dart';
import 'addUser.dart' as mainpage;
import 'displayClient.dart' as displayClientPage;
import 'displayAdmin.dart' as displayAdminPage;
import 'editMail.dart' as mail;
import 'inactiveUser.dart' as inactivePage;

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => displayAdminPage.AdminUsersScreen(),
      ),
    );
  }

  void goToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => mainpage.UserForm()),
    );
  }

  void goToDisplayClients(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            displayClientPage.MyHomePage(title: "Display Clients"),
      ),
    );
  }

  void goToEditMail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => mail.PasswordUpdateForm()),
    );
  }

  void goToInactive(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => inactivePage.ActiveInactiveForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Admin Menu'),
      ),
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
                  child: Text("Display all Employees"),
                ),
              ),

              SizedBox(height: 16),

              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    goToEditMail(context);
                  },
                  child: Text("Edit a password"),
                ),
              ),

              SizedBox(height: 16),

              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    goToInactive(context);
                  },
                  child: Text("Activate/Inactivate Page"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
