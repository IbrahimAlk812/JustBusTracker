import 'package:flutter/material.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف'),
        backgroundColor: Colors.indigo, // لون مختلف لتمييز واجهة المشرف
      ),
      // القائمة الجانبية (مهمة اليوم 1 لزيد)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('القائمة الرئيسية', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(leading: const Icon(Icons.dashboard), title: const Text('الإحصائيات'), onTap: () {}),
            ListTile(leading: const Icon(Icons.bus_alert), title: const Text('إدارة الباصات'), onTap: () {}),
            ListTile(leading: const Icon(Icons.report), title: const Text('الشكاوى'), onTap: () {}),
          ],
        ),
      ),
      // منطقة البطاقات الإحصائية (مهمة اليوم 2 لزيد)
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // عرض بطاقتين في كل سطر
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildStatusCard('الباصات النشطة', '12', Icons.directions_bus, Colors.blue),
            _buildStatusCard('رحلات اليوم', '45', Icons.route, Colors.green),            _buildStatusCard('شكاوى معلقة', '3', Icons.warning, Colors.red),
            _buildStatusCard('طلاب مسجلين', '120', Icons.people, Colors.orange),
          ],
        ),
      ),
    );
  }

  // "Helper Function" لبناء البطاقات بسرعة (احترافية برمجية)
  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 20, color: color)),
        ],
      ),
    );
  }
}