import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorStatisticsView extends StatefulWidget {
  const SupervisorStatisticsView({super.key});

  @override
  State<SupervisorStatisticsView> createState() =>
      _SupervisorStatisticsViewState();
}

class _SupervisorStatisticsViewState extends State<SupervisorStatisticsView> {
  // دالة لجلب الإحصائيات الحقيقية من قاعدة البيانات
  Future<Map<String, int>> _fetchRealStatistics() async {
    final client = Supabase.instance.client;

    try {
      // جلب البيانات البسيطة ثم حساب طولها
      final studentsRes = await client
          .from('profiles')
          .select('id')
          .eq('role', 'student');
      final driversRes = await client
          .from('profiles')
          .select('id')
          .eq('role', 'driver');
      final complaintsRes = await client
          .from('complaints')
          .select('id')
          .eq('status', 'pending');
      final busesRes = await client.from('buses').select('id');

      return {
        'students': (studentsRes as List).length,
        'drivers': (driversRes as List).length,
        'complaints': (complaintsRes as List).length,
        'buses': (busesRes as List).length,
      };
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return {'students': 0, 'drivers': 0, 'complaints': 0, 'buses': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'لوحة تحكم الإحصائيات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF246BFD), Color(0xFF5A8BFF)],
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _fetchRealStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats =
              snapshot.data ??
              {'students': 0, 'drivers': 0, 'complaints': 0, 'buses': 0};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'نظرة عامة على النظام',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // استخدام GridView لعرض البطاقات بشكل أنيق
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildStatCard(
                      'إجمالي الطلاب',
                      stats['students'].toString(),
                      Icons.school,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'الباصات المسجلة',
                      stats['buses'].toString(),
                      Icons.directions_bus,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'السائقين',
                      stats['drivers'].toString(),
                      Icons.person_pin,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'شكاوى معلقة',
                      stats['complaints'].toString(),
                      Icons.warning_amber_rounded,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 25,
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
