import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  // أخذ نسخة من الاتصال بقاعدة البيانات باستخدام المتغير الداخلي الموحد
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
  // 3. دالة حجز مقعد (الطالب)
  // ==========================================
  Future<String> bookSeat(
    String tripId,
    String busId, {
    String boardingType = 'المجمع',
    String? stationName,
    double? lat,
    double? lng,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 'error_not_logged_in';

      // التأكد أن الطالب ليس لديه حجز نشط آخر
      final existingRes = await Supabase.instance.client
          .from('reservations')
          .select()
          .eq('user_id', userId)
          .eq('status', 'نشط');
      if (existingRes.isNotEmpty) return 'already_booked';

      // جلب السعة الكلية من الباص، والركاب الحاليين من الرحلة!
      final busData = await Supabase.instance.client
          .from('buses')
          .select('capacity')
          .eq('id', busId)
          .single();
      int capacity = int.tryParse(busData['capacity']?.toString() ?? '0') ?? 0;

      final tripData = await Supabase.instance.client
          .from('trips')
          .select('current_passengers')
          .eq('id', tripId)
          .single();
      int currentPassengers =
          int.tryParse(tripData['current_passengers']?.toString() ?? '0') ?? 0;

      if (currentPassengers >= capacity) return 'full';

      // تسجيل الحجز مع معرف الرحلة
      await Supabase.instance.client.from('reservations').insert({
        'user_id': userId,
        'bus_id': busId,
        'trip_id': tripId, // 🌟 المعرف الجديد
        'status': 'نشط',
        'boarding_type': boardingType,
        'station_name': stationName,
        'latitude': lat,
        'longitude': lng,
      });

      // 🌟 زيادة العداد في جدول الرحلات (وليس الباصات)
      await Supabase.instance.client
          .from('trips')
          .update({'current_passengers': currentPassengers + 1})
          .eq('id', tripId);
      return 'success';
    } catch (e) {
      print('Booking error: $e');
      return 'error';
    }
  }

  // ==========================================
  // 4. دالة جلب معرف الباص المحجوز (تم تنظيفها وفصلها بشكل مستقل تماماً)
  // ==========================================
  Future<String?> getUserBookedBusId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // الاستعلام من جدول الحجوزات عن الحجز الفعال "نشط" فقط
      final existingReservations = await _supabase
          .from('reservations')
          .select('bus_id')
          .eq('user_id', userId)
          .eq(
            'status',
            'نشط',
          ) // 🌟 قراءة الحجز النشط وتجاهل الملغي لفتح الأزرار
          .limit(1);

      if (existingReservations.isNotEmpty) {
        return existingReservations.first['bus_id'].toString();
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في جلب حجز الطالب: $e');
      return null;
    }
  }

  // ==========================================
  // 5. دالة إلغاء الحجز من واجهة الباصات (تم تعديلها للتحديث بدلاً من الحذف للتزامن الشامل)
  // ==========================================
  Future<String> cancelReservation(String busId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 'error_not_logged_in';

      // 1. 🌟 تحويل الإلغاء إلى تحديث للحالة لتصبح "ملغي" بدلاً من الحذف ليتطابق مع شاشة رحلتي
      await _supabase
          .from('reservations')
          .update({'status': 'ملغي'})
          .eq('user_id', userId)
          .eq('bus_id', busId)
          .eq('status', 'نشط'); // تعديل الحجز النشط فقط

      // 2. جلب بيانات الباص لتحديث العداد
      final busData = await _supabase
          .from('buses')
          .select('bus_number, current_passengers')
          .eq('id', busId)
          .single();

      final int currentPassengers = busData['current_passengers'] ?? 0;
      final String busNumber = busData['bus_number']?.toString() ?? 'غير محدد';

      // 3. إنقاص العداد بشكل آمن
      final newCount = currentPassengers > 0 ? currentPassengers - 1 : 0;
      await _supabase
          .from('buses')
          .update({'current_passengers': newCount})
          .eq('id', busId);

      // 4. إرسال إشعار فوري للمشرف
      final studentData = await _supabase
          .from('profiles')
          .select('name, university_id')
          .eq('id', userId)
          .maybeSingle();

      final studentName = studentData?['name'] ?? 'طالب';
      final studentId = studentData?['university_id'] ?? 'غير معروف';

      final notificationMessage =
          'قام الطالب $studentName (رقم: $studentId) بإلغاء حجزه في باص رقم $busNumber. المقاعد المحجوزة الآن: $newCount';

      // إدراج الإشعار في جدول notifications
      await _supabase.from('notifications').insert({
        'type': 'cancellation',
        'message': notificationMessage,
        'date_time': DateTime.now().toIso8601String(),
      });

      return 'success';
    } catch (e) {
      print('🔥 خطأ أثناء إلغاء الحجز: $e');
      return 'error';
    }
  }
}
