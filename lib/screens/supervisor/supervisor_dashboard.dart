import 'package:flutter/material.dart';
import 'supervisor_statistics_view.dart'; 
import 'supervisor_bus_table.dart'; 
import 'complaints_view.dart'; // استدعاء الملف الجديد الذي أنشأناه

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;

  // قائمة الشاشات: الترتيب مهم جداً لأنه يطابق ترتيب الأزرار في الأسفل
  final List<Widget> _pages = [
    const SupervisorStatisticsView(), // 0: شاشة البطاقات القديمة
    const SupervisorBusTable(),       // 1: شاشة جدول زيد
    const ComplaintsView()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الـ body يعرض الشاشة المناسبة من القائمة أعلاه بناءً على الرقم
      body: _pages[_currentIndex],
      
      // الشريط السفلي للتنقل
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // تحديث الرقم عند الضغط لتتغير الشاشة
          });
        },
        // ألوان الشريط لتحسين المظهر
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'الإحصائيات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'جدول المراقبة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'الشكاوى',
          ),
        ],
      ),
    );
  }
}