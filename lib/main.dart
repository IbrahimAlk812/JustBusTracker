import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_bus_tracker/screens/driver/driver_home_screen.dart';
import 'package:just_bus_tracker/screens/student/bus_list_view_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/auth/login_screen.dart';
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_bus_table.dart';
import 'package:just_bus_tracker/screens/driver/bus_info_card.dart';
import 'package:just_bus_tracker/screens/driver/driver_home_screen.dart';

// ... other imports ...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف البيئة أولاً
  await dotenv.load(fileName: ".env");

  // استخدام المفاتيح المشفرة
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Just Bus Tracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),

      //home: const StudentHomeScreen(),
      //home: const SupervisorDashboard()
      //home: const DriverHomeScreen()
      home: const LoginScreen(),
    );
  }
}
