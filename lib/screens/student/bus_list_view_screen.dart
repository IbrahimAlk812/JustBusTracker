import 'package:flutter/material.dart';
import 'package:just_bus_tracker/services/database_service.dart'; 

class BusListViewScreen extends StatefulWidget {
  const BusListViewScreen({super.key});

  @override
  State<BusListViewScreen> createState() => _BusListViewScreenState();
}

class _BusListViewScreenState extends State<BusListViewScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showNotification(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _processBooking(String busId) async {
    final status = await _dbService.bookSeat(busId);

    if (status == 'success') {
      _showNotification('تم حجز المقعد بنجاح!', true);
      setState(() {}); 
    } else {
      _showNotification('فشل الحجز: الباص ممتلئ.', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'الباصات المتاحة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
          ),
        ),
      ),
      // جلب البيانات مرة واحدة فقط من الجدول
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.getBuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد باصات متاحة حالياً.'));
          }

          final buses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              
              // 1️⃣ استخدام أسماء الأعمدة المتطابقة تماماً مع صورتك في Supabase
              final String busId = bus['id'].toString(); 
              final String busNumber = bus['bus_number']?.toString() ?? 'N/A';
              final String routeName = bus['route']?.toString() ?? 'مسار غير محدد';
              
              // 2️⃣ حساب السعة المتاحة فوراً بدون دوال خارجية تسبب أخطاء
              final int maxCapacity = int.tryParse(bus['capacity']?.toString() ?? '0') ?? 0;
              final int currentPassengers = int.tryParse(bus['current_passengers']?.toString() ?? '0') ?? 0;
              
              final int availableSeats = maxCapacity - currentPassengers;
              final bool isFull = availableSeats <= 0;

              // عرض البطاقة مباشرة
              return _buildBusCard(
                busId,       
                busNumber,   
                routeName,   
                availableSeats,
                isFull,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBusCard(
    String id,
    String busNumber,
    String routeName,
    int availableSeats,
    bool isFull,
  ) { 
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_bus,
                  color: Color(0xFF1A237E),
                  size: 30,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'باص رقم $busNumber', 
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        routeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 18,
                      color: isFull ? Colors.red : Colors.blueGrey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isFull ? 'ممتلئ' : '$availableSeats مقاعد متاحة',
                      style: TextStyle(
                        color: isFull ? Colors.red : Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: isFull ? null : () => _processBooking(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'احجز الآن',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}