import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  // أخذ نسخة من الاتصال بقاعدة البيانات
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. دالة جلب قائمة الباصات
  // ==========================================
  Future<List<Map<String, dynamic>>> getBuses() async {
    try {
      // جلب كل الباصات من جدول buses
      final List<dynamic> response = await _supabase.from('buses').select();
      
      // تحويل البيانات لتكون قابلة للاستخدام في التطبيق
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ خطأ في جلب الباصات: $e');
      return []; 
    }
  }

  // ==========================================
  // 2. دالة حساب السعة المتاحة لباص معين
  // ==========================================
  Future<int> getAvailableCapacity(String busNumber, int totalCapacity) async {
    try {
      // البحث في جدول الحجوزات عن عدد الحجوزات "النشطة"
      final response = await _supabase
          .from('reservations')
          .select('id')
          .eq('bus_number', busNumber)
          .eq('status', 'نشط')
          .count(CountOption.exact);

      int reservedSeats = response.count ?? 0;
      int availableSeats = totalCapacity - reservedSeats;
      
      return availableSeats > 0 ? availableSeats : 0;
    } catch (e) {
      print('❌ خطأ في حساب السعة للباص $busNumber: $e');
      return 0;
    }
  }
  // ==========================================
  // 3. دالة حجز مقعد (تتصل بـ RPC في Supabase)
  // ==========================================
  Future<String> bookSeat(String busNumber) async {
    try {
      // جلب ID الطالب المسجل دخوله حالياً
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 'error_not_logged_in';

      // استدعاء الدالة (RPC) اللي كتبناها بالـ SQL
      final response = await _supabase.rpc(
        'book_bus_seat',
        params: {
          'p_student_id': currentUser.id,
          'p_bus_number': busNumber,
        },
      );

      return response.toString(); // سترجع إما 'success' أو 'full'

    } catch (e) {
      print('❌ خطأ في عملية الحجز: $e');
      return 'error';
    }
  }
}