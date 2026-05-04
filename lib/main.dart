import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/student/login_screen.dart'; 

void main() async {
  // 1. ضمان تهيئة جميع خدمات فلاتر قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();

  // 2. ربط التطبيق بمشروع Supabase (البيانات التي أرسلها إبراهيم الكردي)
  await Supabase.initialize(
    url: 'https://regtuxnoulgwfpyegohc.supabase.co',
    anonKey: 'sb_publishable_yl_OWdKFQIhmuLIOba2V9A_FtoPMYev',
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}