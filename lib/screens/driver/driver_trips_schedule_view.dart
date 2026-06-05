import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverTripsScheduleView extends StatefulWidget {
  const DriverTripsScheduleView({super.key});

  @override
  State<DriverTripsScheduleView> createState() =>
      _DriverTripsScheduleViewState();
}

class _DriverTripsScheduleViewState extends State<DriverTripsScheduleView> {
  Map<String, dynamic>? _driverInfo;
  Map<String, dynamic>? _busInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverAndBusData();
  }

  Future<void> _fetchDriverAndBusData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .limit(1);
      final busRes = await Supabase.instance.client
          .from('buses')
          .select('id, bus_number, capacity')
          .eq('driver_id', userId)
          .limit(1);

      if (mounted) {
        setState(() {
          _driverInfo = profileRes.isNotEmpty ? profileRes.first : null;
          _busInfo = busRes.isNotEmpty ? busRes.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching driver schedule data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 تصميم بطاقة الرحلة (بدون تاريخ، وقت فقط)
  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.alt_route, color: Colors.green, size: 28),
        ),
        title: Text(
          trip['route_name'] ?? 'مسار غير محدد',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'تتكرر يومياً | وقت الانطلاق: ${trip['departure_time']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: trip['status'] == 'مجدولة'
                ? Colors.blue.shade50
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            trip['status'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: trip['status'] == 'مجدولة'
                  ? Colors.blue.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'جدول الرحلات اليومية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF246BFD),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // بطاقة هوية السائق والباص
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 35,
                              backgroundColor: Color(0xFF246BFD),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _driverInfo?['name'] ?? 'اسم السائق غير متوفر',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF246BFD),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _busInfo != null
                                    ? 'يقود باص رقم: ${_busInfo!['bus_number']}'
                                    : 'غير مرتبط بباص حالياً',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // التنويه بأن الرحلات تتكرر
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'هذه الرحلات مجدولة للعمل يومياً من الأحد إلى الخميس في نفس الأوقات المحددة.',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // القائمة
                    Expanded(
                      child: _busInfo == null
                          ? const Center(
                              child: Text(
                                'يجب أن يربطك المشرف بباص لتظهر رحلاتك.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : StreamBuilder<List<Map<String, dynamic>>>(
                              // 🌟 تم إزالة فلترة التواريخ، نعتمد على الوقت فقط
                              stream: Supabase.instance.client
                                  .from('trips')
                                  .stream(primaryKey: ['id'])
                                  .eq('bus_id', _busInfo!['id'].toString())
                                  .order('departure_time', ascending: true),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'لا يوجد رحلات مبرمجة لك.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  );
                                }

                                final trips = snapshot.data!;
                                return ListView.builder(
                                  itemCount: trips.length,
                                  itemBuilder: (context, index) {
                                    return _buildTripCard(trips[index]);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
