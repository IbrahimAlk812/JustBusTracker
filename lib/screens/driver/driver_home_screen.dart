import 'package:flutter/material.dart';
// سنقوم بإنشاء هذه الملفات في الخطوات القادمة
import 'package:just_bus_tracker/screens/driver/driver_map_tracking_view.dart';
import 'package:just_bus_tracker/screens/driver/driver_complaints_view.dart';
import 'package:just_bus_tracker/screens/student/student_profile_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  // قائمة الشاشات التي سيتنقل بينها السائق
  final List<Widget> _screens = [
    const DriverMapTrackingView(), // 🗺️ شاشة الرحلة الحالية (الخريطة + التتبع)
    const DriverComplaintsView(), // ⚠️ شاشة الشكاوى والأعطال
    const StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens, // أو اسم المصفوفة التي تحتوي على شاشات السائق لديك
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF246BFD), // لون الجامعة
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'الرحلة الحالية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'الشكاوى',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
