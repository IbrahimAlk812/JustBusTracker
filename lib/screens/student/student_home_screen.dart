import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BusesListView(), 
    const Center(child: Text("شاشة تتبع الباص (قيد التطوير)")),
    const Center(child: Text("حسابي")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'الباصات'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'التتبع'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

class BusesListView extends StatelessWidget {
  const BusesListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الباصات المتاحة'),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getBuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد باصات متاحة حالياً'));
          }
          final buses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) => BusCard(bus: buses[index], dbService: dbService),
          );
        },
      ),
    );
  }
}

// ==================================================
// ويدجت مستقل لكل باص (مُحدّث ليعمل بنظام Realtime Stream الآمن)
// ==================================================

class BusCard extends StatefulWidget {
  final Map<String, dynamic> bus;
  final DatabaseService dbService;

  const BusCard({Key? key, required this.bus, required this.dbService}) : super(key: key);

  @override
  State<BusCard> createState() => _BusCardState();
}

class _BusCardState extends State<BusCard> {
  bool isBooking = false; 

  @override
  Widget build(BuildContext context) {
    final int totalCapacity = widget.bus['capacity'] ?? 50; 
    final String busNumber = widget.bus['bus_number'];

    return StreamBuilder<List<Map<String, dynamic>>>(
      // 📡 نفتح قناة الاتصال العامة (بدون فلاتر هنا لتجنب مشاكل الإصدارات)
      stream: Supabase.instance.client
          .from('reservations')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        
        // 1. الفلترة الذكية داخل Dart (نأخذ فقط باصنا الحالي والحجز النشط)
        final allReservations = snapshot.data ?? [];
        final activeReservations = allReservations.where((res) => 
            res['bus_number'] == busNumber && res['status'] == 'نشط'
        ).toList();

        // 2. حساب عدد الكراسي المحجوزة
        int reservedCount = activeReservations.length;
        
        // 3. حساب السعة المتاحة
        int availableCapacity = totalCapacity - reservedCount;
        if (availableCapacity < 0) availableCapacity = 0;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'رقم الباص: $busNumber',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.directions_bus, color: Colors.blue[800]),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'المسار: ${widget.bus['route'] ?? 'غير محدد حالياً'}',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المقاعد المتاحة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '$availableCapacity مقعد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: availableCapacity > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: availableCapacity > 0 ? Colors.blue[800] : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: availableCapacity > 0 && !isBooking
                          ? () async {
                              setState(() => isBooking = true);
                              
                              final result = await widget.dbService.bookSeat(busNumber);
                              
                              if (mounted) {
                                if (result == 'success') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم الحجز بنجاح! 🎉'), backgroundColor: Colors.green),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('الرجاء تسجيل الدخول أولاً لإتمام الحجز'), backgroundColor: Colors.orange),
                                  );
                                }
                                setState(() => isBooking = false);
                              }
                            }
                          : null,
                      child: isBooking 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('احجز مقعدك', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}