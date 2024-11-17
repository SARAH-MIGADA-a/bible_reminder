import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible Reminder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final TextEditingController reminderController = TextEditingController();
  final String verseOfTheDay = "John 3:16 - For God so loved the world...";

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Initialize timezone data
    _initializeNotifications();
    _loadReminder();
  }

  // Initialize notifications
  void _initializeNotifications() {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const initializationSettings =
    InitializationSettings(android: androidSettings);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Load reminder time from shared preferences
  Future<void> _loadReminder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      reminderController.text = prefs.getString('reminder_time') ?? '';
    });
  }

  // Save reminder time and schedule notification
  Future<void> _saveReminder() async {
    final reminderTime = reminderController.text.trim();

    if (_validateTime(reminderTime)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reminder_time', reminderTime);

      final parsedTime = _parseTime(reminderTime);
      if (parsedTime != null) {
        _scheduleDailyReminder(parsedTime);
        _showSnackbar("Reminder set for $reminderTime");
      } else {
        _showSnackbar("Invalid time. Please try again.");
      }
    } else {
      _showSnackbar("Invalid format. Use 'hh:mm AM/PM'.");
    }
  }

  // Schedule a daily reminder notification
  void _scheduleDailyReminder(tz.TZDateTime time) {
    flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Bible Reminder',
      'Don\'t forget to read your Bible!',
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bible_reminder_channel', // Channel ID
          'Bible Reminder Notifications', // Channel Name
          channelDescription: 'Daily Bible verse reminder', // Description
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Parse time string to a TZDateTime object
  tz.TZDateTime? _parseTime(String timeString) {
    try {
      final timeParts = timeString.split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1].split(' ')[0]);
      final isPM = timeString.contains('PM');

      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time is earlier than now, schedule for the next day
      return scheduledTime.isBefore(now)
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;
    } catch (e) {
      return null; // Return null for invalid input
    }
  }

  // Validate user input time format
  bool _validateTime(String time) {
    final regex = RegExp(r'^\d{1,2}:\d{2} (AM|PM)$');
    return regex.hasMatch(time);
  }

  // Show a snackbar for user feedback
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Reminder App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Verse of the Day",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              verseOfTheDay,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reminderController,
              decoration: const InputDecoration(
                labelText: 'Set Reminder Time (e.g., 8:00 AM)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReminder,
              child: const Text('Save Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
