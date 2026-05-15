import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorBusTable extends StatelessWidget {
  const SupervisorBusTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة تحكم المشرف - الباصات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "جدول المراقبة اللحظي",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              // 📡 1. الاستماع لجدول الباصات (لمعرفة السعة والمسار)
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('buses')
                    .stream(primaryKey: ['bus_number']),
                builder: (context, busesSnapshot) {
                  if (busesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!busesSnapshot.hasData || busesSnapshot.data!.isEmpty) {
                    return const Center(child: Text("لا توجد بيانات باصات متاحة"));
                  }

                  final buses = busesSnapshot.data!;

                  // 📡 2. الاستماع لجدول الحجوزات (لعد الركاب لحظياً)
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('reservations')
                        .stream(primaryKey: ['id'])
                        .eq('status', 'نشط'), // نحسب الحجوزات الفعالة فقط
                    builder: (context, reservationsSnapshot) {
                      
                      final activeReservations = reservationsSnapshot.data ?? [];

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: DataTable(
                              headingRowColor: const WidgetStatePropertyAll(Color(0xFFBBDEFB)),
                              columns: const [
                                DataColumn(label: Text('رقم الباص', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المسار', style: TextStyle(fontWeight: FontWeight.bold))),
                                // إضافة عمود الحجوزات الجديد
                                DataColumn(label: Text('الحجوزات', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: buses.map((bus) {
                                final String busNumber = bus['bus_number'].toString();
                                final int capacity = bus['capacity'] ?? 50;
                                
                                // فلترة وعد الحجوزات الخاصة بهذا الباص تحديداً
                                final int reservedCount = activeReservations
                                    .where((res) => res['bus_number'] == busNumber)
                                    .length;

                                return DataRow(cells: [
                                  DataCell(Text(busNumber)),
                                  DataCell(Text(bus['route'] ?? 'غير محدد')),
                                  // عرض الرقم (المحجوز / السعة الكلية) مع تلوين ذكي
                                  DataCell(
                                    Text(
                                      '$reservedCount / $capacity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        // إذا امتلأ الباص يصبح الرقم أحمر، وإلا أخضر
                                        color: reservedCount >= capacity ? Colors.red : Colors.green[700],
                                      ),
                                    ),
                                  ),
                                  DataCell(_buildStatusIcon(bus['status'])),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لاختيار الأيقونة واللون بناءً على الحالة
  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'نشط':
        return const Icon(Icons.directions_bus, color: Colors.green);
      case 'طوارئ':
        return const Icon(Icons.warning, color: Colors.red);
      case 'صيانة':
        return const Icon(Icons.build, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}