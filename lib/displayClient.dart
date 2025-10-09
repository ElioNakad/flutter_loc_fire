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

class PushedData {
  final String email;
  final String dateTime;
  final String location;
  final String device;

  PushedData({
    required this.email,
    required this.dateTime,
    required this.location,
    required this.device,
  });

  factory PushedData.fromJson(Map<dynamic, dynamic> json) {
    return PushedData(
      email: json['email']?.toString() ?? '',
      dateTime: json['date']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      device: json['deviceId']?.toString() ?? '',
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<PushedData> dataList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    readPushedData();
  }

  /// Load all data from pushed table
  Future<void> readPushedData() async {
    setState(() => _isLoading = true);

    try {
      final pushedSnap = await FirebaseDatabase.instance.ref("pushed").get();
      if (!pushedSnap.exists) {
        dataList = [];
        return;
      }

      final pushedData = pushedSnap.value as Map<dynamic, dynamic>;

      dataList = pushedData.values
          .map((e) => PushedData.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Sort by date and time, newest first
      dataList.sort((a, b) {
        if (a.dateTime.isEmpty || b.dateTime.isEmpty) return 0;
        final dateA = DateTime.tryParse(a.dateTime.replaceAll(" ", "T"));
        final dateB = DateTime.tryParse(b.dateTime.replaceAll(" ", "T"));
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // descending order (newest first)
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load data"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Search data by date range
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
      final pushedSnap = await FirebaseDatabase.instance.ref("pushed").get();
      if (!pushedSnap.exists) {
        dataList = [];
        return;
      }

      final pushedData = pushedSnap.value as Map<dynamic, dynamic>;
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(
        endDate,
      ).add(const Duration(hours: 23, minutes: 59, seconds: 59));

      dataList = pushedData.values
          .map((e) => PushedData.fromJson(Map<String, dynamic>.from(e)))
          .where((data) {
            if (data.dateTime.isEmpty) return false;

            // convert "yyyy-MM-dd HH:mm:ss" → proper DateTime
            final date = DateTime.tryParse(data.dateTime.replaceAll(" ", "T"));
            if (date == null) return false;

            // Check if date is within range (inclusive of both start and end dates)
            return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
                (date.isAtSameMomentAs(end) || date.isBefore(end));
          })
          .toList();

      // Sort by date and time, newest first
      dataList.sort((a, b) {
        if (a.dateTime.isEmpty || b.dateTime.isEmpty) return 0;
        final dateA = DateTime.tryParse(a.dateTime.replaceAll(" ", "T"));
        final dateB = DateTime.tryParse(b.dateTime.replaceAll(" ", "T"));
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // descending order (newest first)
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to filter data"),
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

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final _Controller1 = TextEditingController();
    final _Controller2 = TextEditingController();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Display Clients')),
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
                          onPressed: () => searchByDate(
                            _Controller1.text,
                            _Controller2.text,
                          ),
                          child: const Text("Search by Date"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _Controller1.clear();
                            _Controller2.clear();
                            readPushedData();
                          },
                          child: const Text("Show All Data"),
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
                  : dataList.isEmpty
                  ? const Center(
                      child: Text(
                        "No data found",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: dataList.length,
                      itemBuilder: (context, index) {
                        PushedData data = dataList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              data.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  "Time: ${data.dateTime.isNotEmpty ? data.dateTime : "N/A"}",
                                ),
                                Text(
                                  "Location: ${data.location.isNotEmpty ? data.location : "N/A"}",
                                ),
                                Text(
                                  "Device Id: ${data.device.isNotEmpty ? data.device : "N/A"}",
                                ),
                              ],
                            ),
                            trailing:
                                data.location.isNotEmpty &&
                                    data.location.contains(",")
                                ? ElevatedButton(
                                    onPressed: () => openInMaps(data.location),
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
      ),
    );
  }
}
