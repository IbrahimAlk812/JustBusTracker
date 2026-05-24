import 'package:flutter/material.dart';
// استدعاء الشاشات الثلاثة
import 'package:just_bus_tracker/screens/student/bus_list_view_screen.dart';
import 'package:just_bus_tracker/screens/student/bus_map_view.dart';
import 'package:just_bus_tracker/screens/student/profile_view.dart'; // تأكدنا من اسم الملف

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  // القائمة الصحيحة بأسماء الكلاسات المضبوطة
  final List<Widget> _screens = [
    const BusListViewScreen(),
    const StudentMapView(), // خريطتك الجديدة
    const ProfileView(),    // تعديل اسم كلاس البروفايل
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استدعاء نفس المتغير _screens
      body: _screens[_currentIndex], 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'الباصات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'التتبع',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}