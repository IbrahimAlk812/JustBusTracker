import 'package:flutter/material.dart';
import 'package:just_bus_tracker/screens/student/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://regtuxnoulgwfpyegohc.supabase.co',
    anonKey: 'sb_publishable_yl_OwdKFQHmulTOba2V9A_FtoPMYev',
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
      home: const LoginScreen(),
    );
  }
}
