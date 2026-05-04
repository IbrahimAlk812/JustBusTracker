import 'package:flutter/material.dart';
import 'bus_map_view.dart';
import 'my_reservations_view.dart';
import 'profile_view.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // المتغير الذي يحدد الشاشة المختارة حالياً
  int _selectedIndex = 0;

  // قائمة الشاشات التي سيتم التنقل بينها (سنقوم بتعبئتها لاحقاً)
  static const List<Widget> _widgetOptions = <Widget>[
    BusMapView(),        // بدلاً من النص القديم
    MyReservationsView(), // بدلاً من النص القديم
    ProfileView(),       // بدلاً من النص القديم
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Just Bus Tracker'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      
      // هنا الجزء المطلوب لمهمة اليوم الثاني: شريط التنقل السفلي
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'حجوزاتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}