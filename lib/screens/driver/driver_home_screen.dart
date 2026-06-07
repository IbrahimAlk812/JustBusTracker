import 'package:flutter/material.dart';
import 'package:just_bus_tracker/screens/driver/driver_map_tracking_view.dart';
import 'package:just_bus_tracker/screens/driver/driver_complaints_view.dart';
import 'package:just_bus_tracker/screens/student/student_profile_screen.dart';
// 🌟 استدعاء الشاشة الجديدة
import 'package:just_bus_tracker/screens/driver/driver_trips_schedule_view.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DriverMapTrackingView(),
    const DriverTripsScheduleView(), // 🌟 الشاشة الجديدة المضافة (الجدول)
    const DriverComplaintsView(),
    const StudentProfileScreen(), // (يمكنك استبدالها لاحقاً بشاشة حساب مخصصة للسائق إن أردت)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType
            .fixed, // 🌟 ضروري عند وجود أكثر من 3 تبويبات
        selectedItemColor: const Color(0xFF246BFD),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
            icon: Icon(Icons.calendar_month),
            label: 'رحلاتي',
          ), // 🌟 التبويب الجديد
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
