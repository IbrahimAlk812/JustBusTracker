import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// استدعاء صفحة الخريطة بالمسار الصحيح
import 'package:just_bus_tracker/screens/student/bus_map_view.dart';

// بقية الـ Imports الخاصة بالصفحات الأخرى
import 'package:just_bus_tracker/screens/student/bus_list_view_screen.dart';
import 'package:just_bus_tracker/screens/student/login_screen.dart';
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_bus_table.dart';
import 'package:just_bus_tracker/screens/driver/bus_info_card.dart';
import 'package:just_bus_tracker/screens/driver/driver_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف البيئة .env
  await dotenv.load(fileName: ".env");

  // تهيئة سوبابيس
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

      // فتح شاشة الخريطة مباشرة عند تشغيل التطبيق (بدون const)
      home: busMapViewScreen(),
    );
  }
}
