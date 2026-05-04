import 'package:flutter/material.dart';
import 'package:just_bus_tracker/screens/student/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// تأكد من استيراد الشاشة الرئيسية للطالب فقط
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';
// تأكد من استيراد الشاشة الرئيسية للطالب فقط

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

  // داخل كود الـ main.dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // الانطلاقة تبدأ من هنا دائماً
    );
  
  }
}
        
      // نقطة الانطلاق هي الشاشة التي تحتوي على الـ BottomNavigationBar
      
    
  

