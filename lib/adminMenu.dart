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
    return MaterialApp(
      title: 'Firebase Form',
      theme: ThemeData(
        primaryColor: Color(0xFF003D5C),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF003D5C),
          secondary: Color(0xFFFF6B5A),
        ),
      ),
      home: Menu(),
    );
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

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003D5C),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Admin Menu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF003D5C),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003D5C), Color(0xFF00527A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage users and system settings',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Cards
            Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildMenuCard(
                    title: "Display All Admins",
                    subtitle: "View list of administrator accounts",
                    icon: Icons.shield_rounded,
                    iconColor: Color(0xFF6366F1),
                    onTap: () => goToDisplayAdmins(context),
                  ),
                  _buildMenuCard(
                    title: "Sign Up New User",
                    subtitle: "Create a new user account",
                    icon: Icons.person_add_rounded,
                    iconColor: Color(0xFF10B981),
                    onTap: () => goToSignUp(context),
                  ),
                  _buildMenuCard(
                    title: "Display All Employees",
                    subtitle: "View list of employee accounts",
                    icon: Icons.people_rounded,
                    iconColor: Color(0xFFFF6B5A),
                    onTap: () => goToDisplayClients(context),
                  ),
                  _buildMenuCard(
                    title: "Edit Password",
                    subtitle: "Change user password credentials",
                    icon: Icons.lock_reset_rounded,
                    iconColor: Color(0xFFF59E0B),
                    onTap: () => goToEditMail(context),
                  ),
                  _buildMenuCard(
                    title: "Activate/Inactivate Users",
                    subtitle: "Manage user account status",
                    icon: Icons.toggle_on_rounded,
                    iconColor: Color(0xFF8B5CF6),
                    onTap: () => goToInactive(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
