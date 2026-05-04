import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// تأكد من استيراد الشاشة الرئيسية للطالب فقط
import 'package:just_bus_tracker/screens/student/student_home_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      // نقطة الانطلاق هي الشاشة التي تحتوي على الـ BottomNavigationBar
      home: const StudentHomeScreen(), 
    );
  }
}