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
      body: SingleChildScrollView(
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

            // إحصائيات علوية
            FutureBuilder<Map<String, int>>(
              future: _fetchRealStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats =
                    snapshot.data ??
                    {'students': 0, 'drivers': 0, 'complaints': 0, 'buses': 0};

                return GridView.count(
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
                );
              },
            ),

            const SizedBox(height: 35),
            const Divider(),
            const SizedBox(height: 15),

            // 🌟 قسم المراقبة الحية لرحلات اليوم
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'مراقبة إشغال رحلات اليوم (بث حي)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.radar, color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 15),
            const _LiveTripsTracker(), // استدعاء ويدجت المراقبة الحية
          ],
        ),
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

// ==========================================
// 🌟 ويدجت منفصلة لمراقبة الحجوزات الحية للرحلات
// ==========================================
class _LiveTripsTracker extends StatefulWidget {
  const _LiveTripsTracker();

  @override
  State<_LiveTripsTracker> createState() => _LiveTripsTrackerState();
}

class _LiveTripsTrackerState extends State<_LiveTripsTracker> {
  List<Map<String, dynamic>> _todayTripsWithBuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayTrips();
  }

  // جلب كافة رحلات اليوم وتجهيز بيانات الباصات والسائقين التابعة لها
  // جلب كافة الرحلات الثابتة (المجدولة) وتجهيز بيانات الباصات والسائقين التابعة لها
  Future<void> _fetchTodayTrips() async {
    try {
      final client = Supabase.instance.client;

      // 🌟 التعديل هنا: إزالة فحص التاريخ والاعتماد على حالة "مجدولة" فقط
      final trips = await client
          .from('trips')
          .select()
          .eq('status', 'مجدولة')
          .order('departure_time', ascending: true);

      final buses = await client.from('buses').select();
      final drivers = await client
          .from('profiles')
          .select('id, name')
          .eq('role', 'driver');

      List<Map<String, dynamic>> merged = [];
      for (var trip in trips) {
        final bus = buses.firstWhere(
          (b) => b['id'].toString() == trip['bus_id'].toString(),
          orElse: () => <String, dynamic>{},
        );

        if (bus.isNotEmpty) {
          final driverId = bus['driver_id']?.toString();
          String driverName = 'غير معيّن';
          if (driverId != null) {
            final driver = drivers.firstWhere(
              (d) => d['id'].toString() == driverId,
              orElse: () => <String, dynamic>{},
            );
            if (driver.isNotEmpty) driverName = driver['name'].toString();
          }

          merged.add({'trip': trip, 'bus': bus, 'driver_name': driverName});
        }
      }

      if (mounted) {
        setState(() {
          _todayTripsWithBuses = merged;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching today trips for live tracker: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_todayTripsWithBuses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            'لا توجد رحلات مجدولة لليوم.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // رادار حي لجدول الحجوزات
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('reservations')
          .stream(primaryKey: ['id'])
          .eq('status', 'نشط'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allActiveReservations = snapshot.data ?? [];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _todayTripsWithBuses.length,
          itemBuilder: (context, index) {
            final item = _todayTripsWithBuses[index];
            final trip = item['trip'];
            final bus = item['bus'];
            final String driverName = item['driver_name'];

            // 🌟 الحل السحري هنا: جلب معرف الرحلة واستخدامه في الفلترة بدلاً من معرف الباص
            final String tripId = trip['id'].toString();
            final int capacity =
                int.tryParse(bus['capacity']?.toString() ?? '0') ?? 0;

            // 🌟 الفلترة بناءً على trip_id فقط
            final tripReservations = allActiveReservations
                .where((r) => r['trip_id'].toString() == tripId)
                .toList();

            final int currentCount = tripReservations.length;
            final int terminalCount = tripReservations
                .where((r) => r['boarding_type'] == 'المجمع')
                .length;
            final int stationCount = tripReservations
                .where((r) => r['boarding_type'] == 'محطة طريق')
                .length;

            final bool isFull = currentCount >= capacity;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات الرحلة والباص
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.alt_route,
                              color: Color(0xFF246BFD),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip['route_name'] ?? 'مسار غير محدد',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'باص رقم: ${bus['bus_number']} | السائق: $driverName',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              trip['departure_time'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // العداد الحي وتفاصيل الحجوزات
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'حالة الحجوزات الحية:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  '$currentCount / $capacity مقعد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isFull ? Colors.red : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: capacity > 0
                                    ? currentCount / capacity
                                    : 0,
                                backgroundColor: Colors.orange.shade100,
                                color: isFull ? Colors.red : Colors.orange,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  '🏢 المجمع: $terminalCount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 15,
                                  color: Colors.grey.shade400,
                                ),
                                Text(
                                  '🚏 الطريق: $stationCount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
