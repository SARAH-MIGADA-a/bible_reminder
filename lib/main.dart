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
    final ThemeData theme = ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'Bible Reminder App',
      theme: theme,
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
  String verseOfTheDay = "John 3:16 - For God so loved the world...";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadReminder();
  }

  void _initializeNotifications() {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const initializationSettings = InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadReminder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      reminderController.text = prefs.getString('reminder_time') ?? '';
    });
  }

  Future<void> _saveReminder() async {
    if (selectedDate == null || selectedTime == null) {
      _showSnackbar("Please select both date and time.");
      return;
    }

    final String reminderTime =
        '${selectedDate!.toLocal().toString().split(' ')[0]} ${selectedTime!.format(context)}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_time', reminderTime);

    final parsedTime = _parseTime(reminderTime);
    if (parsedTime != null) {
      _scheduleDailyReminder(parsedTime);
      _showSnackbar("Reminder set for $reminderTime");
    } else {
      _showSnackbar("Invalid time format.");
    }
  }

  tz.TZDateTime? _parseTime(String timeString) {
    try {
      final dateParts = timeString.split(' ');
      final date = DateTime.parse(dateParts[0]);
      final timeParts = dateParts[1].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1].substring(0, 2));
      final isPM = timeParts[1].contains('PM');

      final scheduledTime = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        isPM ? (hour + 12) % 24 : hour,
        minute,
      );

      return scheduledTime.isBefore(tz.TZDateTime.now(tz.local))
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;
    } catch (e) {
      return null;
    }
  }

  void _scheduleDailyReminder(tz.TZDateTime time) {
    flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Bible Reminder',
      'Don\'t forget to read your Bible!',
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bible_reminder_channel',
          'Bible Reminder Notifications',
          channelDescription: 'Daily Bible verse reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime)
      setState(() {
        selectedTime = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bible Reminder App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: Colors.blue[700],
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Verse of the Day",
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        verseOfTheDay,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: Colors.blue[700],
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Set Reminder",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                color: Colors.blue[700],
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => _selectDate(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Colors.blue[700],
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      selectedDate == null
                                          ? 'Select Date'
                                          : 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () => _selectTime(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.blue[700],
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      selectedTime == null
                                          ? 'Select Time'
                                          : 'Time: ${selectedTime!.format(context)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveReminder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Save Reminder',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}