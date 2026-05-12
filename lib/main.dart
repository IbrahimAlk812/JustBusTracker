import 'package:flutter/material.dart';
import 'package:just_bus_tracker/screens/student/bus_list_view_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/student/login_screen.dart';
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_bus_table.dart';
import 'package:just_bus_tracker/screens/driver/bus_info_card.dart';
import 'package:just_bus_tracker/screens/driver/driver_screen.dart';

// ... other imports ...

void main() async {
  // This line is super important when initializing things before the app runs
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Ibrahim Alkordi's Supabase project
  await Supabase.initialize(
    url: 'https://regtuxnoulgwfpyegohc.supabase.co',
    anonKey: 'sb_publishable_yl_OWdKFQIhmuLIOba2V9A_FtoPMYev',
  );

  runApp(const MyApp()); // Make sure this matches your app's main widget name
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Just Bus Tracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),

      home: const DriverScreen(),
    );
  }
}
