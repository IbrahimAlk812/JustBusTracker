import 'package:flutter/material.dart';
import 'package:just_bus_tracker/services/database_service.dart'; 

class BusListViewScreen extends StatefulWidget {
  const BusListViewScreen({super.key});

  @override
  State<BusListViewScreen> createState() => _BusListViewScreenState();
}

class _BusListViewScreenState extends State<BusListViewScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  late Future<List<Map<String, dynamic>>> _busesFuture;
  String? _bookedBusId; // 🌟 متغير لحفظ رقم الباص الذي حجزه الطالب

  @override
  void initState() {
    super.initState();
    _refreshBuses();
  }

  // 🌟 دالة تقوم بتحديث قائمة الباصات ومعرفة حالة حجز الطالب في نفس الوقت
  void _refreshBuses() {
    setState(() {
      _busesFuture = _dbService.getBuses();
    });
    _loadUserReservation();
  }

  // 🌟 جلب رقم الباص المحجوز لتلوين الزر
  Future<void> _loadUserReservation() async {
    final busId = await _dbService.getUserBookedBusId();
    if (mounted) {
      setState(() {
        _bookedBusId = busId;
      });
    }
  }

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
    _showNotification('جاري تأكيد الحجز...', true);

    final status = await _dbService.bookSeat(busId);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (status == 'success') {
      _showNotification('تم حجز مقعدك بنجاح! 🚌', true);
      _refreshBuses(); // سيتم التحديث وتلوين الزر فوراً
    } else if (status == 'already_booked') {
      _showNotification('لقد قمت بحجز مقعد مسبقاً! لا يمكنك الحجز أكثر من مرة.', false);
      _loadUserReservation(); // لمعرفة الباص وتلوينه في حال كان محجوزاً مسبقاً
    } else if (status == 'full') {
      _showNotification('عذراً، الباص ممتلئ بالكامل.', false);
    } else if (status == 'error_not_logged_in') {
      _showNotification('الرجاء تسجيل الدخول أولاً.', false);
    } else {
      _showNotification('حدث خطأ أثناء الحجز، يرجى المحاولة لاحقاً.', false);
    }
  }

// معالجة منطق إلغاء الحجز
  Future<void> _processCancellation(String busId) async {
    _showNotification('جاري إلغاء الحجز...', true);

    final status = await _dbService.cancelReservation(busId);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (status == 'success') {
      _showNotification('تم إلغاء الحجز بنجاح.', true);
      _refreshBuses(); // تحديث الشاشة لإرجاع الزر لحالته الطبيعية
    } else {
      _showNotification('حدث خطأ أثناء الإلغاء، يرجى المحاولة لاحقاً.', false);
    }
  }

  // إظهار نافذة التحذير قبل الإلغاء
  void _showCancelDialog(String busId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('تأكيد إلغاء الحجز', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد أنك تريد إلغاء حجزك؟\n\n'
            'ملاحظة: الإلغاء المتكرر أو الإلغاء المتأخر قد يعرض حسابك للحظر المؤقت من الحجز للحفاظ على حقوق الطلبة الآخرين.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // إغلاق النافذة
              child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // إغلاق النافذة
                _processCancellation(busId); // تنفيذ الإلغاء
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('نعم، قم بالإلغاء', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
      
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _busesFuture,
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
              
              final String busId = bus['id'].toString(); 
              final String busNumber = bus['bus_number']?.toString() ?? 'N/A';
              final String routeName = bus['route']?.toString() ?? 'مسار غير محدد';
              
              final int maxCapacity = int.tryParse(bus['capacity']?.toString() ?? '0') ?? 0;
              final int currentPassengers = int.tryParse(bus['current_passengers']?.toString() ?? '0') ?? 0;
              
              final int availableSeats = maxCapacity - currentPassengers;
              final bool isFull = availableSeats <= 0;

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
    // 🌟 الهندسة المنطقية لحالة الأزرار
    bool isBookedByMe = (id == _bookedBusId); // هل أنا حجزت هذا الباص تحديداً؟
    bool hasBookedAnyBus = (_bookedBusId != null); // هل أنا حجزت أي باص بشكل عام؟

    // تحديد لون ونص الزر بناءً على الحالة
    Color buttonColor;
    String buttonText;

    if (isBookedByMe) {
      buttonColor = Colors.green; // لون أخضر للباص المحجوز
      buttonText = 'تم الحجز ✔️';
    } else if (isFull) {
      buttonColor = Colors.grey;
      buttonText = 'ممتلئ';
    } else if (hasBookedAnyBus) {
      buttonColor = Colors.grey.shade400; // لون باهت لباقي الباصات لمنع حجزها
      buttonText = 'احجز الآن';
    } else {
      buttonColor = const Color(0xFF1A237E); // اللون الأزرق الطبيعي إذا لم يحجز شيئاً
      buttonText = 'احجز الآن';
    }

    // تعطيل الزر إذا كان ممتلئاً أو إذا كان الطالب قد حجز بالفعل
    bool isButtonDisabled = isFull || hasBookedAnyBus;

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
                  // 🌟 إذا كان الباص محجوزاً من قبلي، أسمح بالضغط لإلغائه
                  onPressed: (isButtonDisabled && !isBookedByMe) 
                      ? null 
                      : () {
                          if (isBookedByMe) {
                            _showCancelDialog(id); // فتح رسالة التحذير
                          } else {
                            _processBooking(id); // عملية الحجز الطبيعية
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor, 
                    disabledBackgroundColor: buttonColor, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonText, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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