import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clients',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Clients'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class User {
  final String email;
  final String fname;
  final String lname;
  final String position;
  final String? dateTime;
  final String? location;
  final String? device;

  User({
    required this.fname,
    required this.lname,
    required this.email,
    required this.position,
    this.dateTime,
    this.location,
    this.device,
  });

  factory User.fromJson(Map<dynamic, dynamic> json) {
    return User(
      email: json['email']?.toString() ?? '',
      fname: json['fname']?.toString() ?? '',
      lname: json['lname']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
    );
  }

  User copyWithPush(Map<dynamic, dynamic> pushJson) {
    return User(
      email: email,
      fname: fname,
      lname: lname,
      position: position,
      dateTime: pushJson['date']?.toString(),
      location: pushJson['location']?.toString(),
      device: pushJson['deviceId']?.toString(),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<User> userList = [];
  bool filtered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    readClients();
  }

  /// Load only clients (exclude admins)
  Future<List<User>> loadClients() async {
    final snapshot = await FirebaseDatabase.instance.ref("users").get();
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;

    return data.values
        .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.position != "Admin")
        .toList();
  }

  Future<void> readClients() async {
    setState(() => _isLoading = true);

    try {
      userList = await loadClients();
      filtered = false;
      print("Loaded ${userList.length} clients from Firebase");
    } catch (e) {
      print("Error reading users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load clients"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Search clients by pushed date
  Future<void> searchByDate(String startDate, String endDate) async {
    if (startDate.isEmpty || endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both start and end dates"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final clients = await loadClients();

      final pushedSnap = await FirebaseDatabase.instance.ref("pushed").get();
      if (!pushedSnap.exists) {
        userList = [];
        return;
      }

      final pushedData = pushedSnap.value as Map<dynamic, dynamic>;
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      final filteredPushes = pushedData.values.where((e) {
        final push = Map<String, dynamic>.from(e);
        final dateStr = push['date']?.toString();
        if (dateStr == null) return false;

        // convert "yyyy-MM-dd HH:mm:ss" → proper DateTime
        final date = DateTime.tryParse(dateStr.replaceAll(" ", "T"));
        if (date == null) return false;

        return date.isAtSameMomentAs(start) ||
            date.isAtSameMomentAs(end) ||
            (date.isAfter(start) && date.isBefore(end));
      });

      userList = [];
      for (var c in clients) {
        for (var p in filteredPushes) {
          final push = Map<String, dynamic>.from(p);
          if (c.email == push['email']) {
            userList.add(c.copyWithPush(push));
          }
        }
      }

      print(
        "Filtered ${userList.length} clients between $startDate and $endDate",
      );
      filtered = true;
    } catch (e) {
      print("Error filtering users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to filter users"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> openInMaps(String coordinates) async {
    final coords = coordinates.split(',');
    if (coords.length != 2) {
      debugPrint("Invalid coordinates format: $coordinates");
      return false;
    }

    final lat = coords[0].trim();
    final lng = coords[1].trim();

    final mapUrls = [
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      "https://maps.apple.com/?q=$lat,$lng",
      "geo:$lat,$lng",
    ];

    for (String url in mapUrls) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    debugPrint("Could not launch any map app for $coordinates");
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final _Controller1 = TextEditingController();
    final _Controller2 = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Display Clients")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _Controller1,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Select the first date",
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      _Controller1.text =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _Controller2,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Select the second date",
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      _Controller2.text =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            searchByDate(_Controller1.text, _Controller2.text),
                        child: const Text("Search by Date"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _Controller1.clear();
                          _Controller2.clear();
                          readClients();
                        },
                        child: const Text("Show All Clients"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : userList.isEmpty
                ? const Center(
                    child: Text(
                      "No client users found",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: userList.length,
                    itemBuilder: (context, index) {
                      User user = userList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            "${user.fname} ${user.lname}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              if (filtered) ...[
                                const SizedBox(height: 8),
                                Text("Time: ${user.dateTime ?? "N/A"}"),
                                Text("Location: ${user.location ?? "N/A"}"),
                                Text("Device Id: ${user.device ?? "N/A"}"),
                              ],
                            ],
                          ),
                          trailing:
                              filtered &&
                                  user.location != null &&
                                  user.location!.contains(",")
                              ? ElevatedButton(
                                  onPressed: () => openInMaps(user.location!),
                                  child: const Text("Open in Maps"),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
