import 'package:flutter/material.dart';

class SupervisorStatisticsView extends StatelessWidget {
  const SupervisorStatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة تحكم المشرف',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildStatCard('الباصات النشطة', '12', Icons.directions_bus, Colors.blue),
            _buildStatCard('رحلات اليوم', '45', Icons.route, Colors.green),
            _buildStatCard('شكاوى معلقة', '3', Icons.warning, Colors.red),
            _buildStatCard('طلاب مسجلين', '120', Icons.people, Colors.orange),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء شكل البطاقة لتقليل تكرار الكود
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            count,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}