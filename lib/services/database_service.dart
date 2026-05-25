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
  // 🚀 دالة حجز المقعد (الطالب)
  // 🚀 دالة حجز المقعد (الطالب)
  Future<String> bookSeat(String busId) async {
    try {
      // 1. التحقق من تسجيل الدخول
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 'error_not_logged_in';

      // 2. 🛑 التحقق من عدم وجود حجز مسبق (منع الحجز المزدوج) بطريقة أكثر أماناً
      final existingReservations = await Supabase.instance.client
          .from('reservations')
          .select()
          .eq('user_id', userId)
          .limit(1); // اطلب نتيجة واحدة فقط بدلاً من maybeSingle

      if (existingReservations.isNotEmpty) {
        return 'already_booked'; // إذا كانت القائمة غير فارغة، يعني أنه حجز مسبقاً
      }

      // 🌟 دالة لمعرفة الباص الذي حجزه الطالب مسبقاً (إن وجد)
      Future<String?> getUserBookedBusId() async {
        try {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) return null;

          final existingReservations = await Supabase.instance.client
              .from('reservations')
              .select('bus_id')
              .eq('user_id', userId)
              .limit(1);

          if (existingReservations.isNotEmpty) {
            return existingReservations.first['bus_id'].toString();
          }
          return null; // إذا لم يقم بالحجز مسبقاً
        } catch (e) {
          print('🔥 خطأ في جلب حجز الطالب: $e');
          return null;
        }
      }

      // 3. جلب بيانات الباص للتحقق من السعة الحالية
      final busData = await Supabase.instance.client
          .from('buses')
          .select('capacity, current_passengers')
          .eq('id', busId)
          .single();

      final int capacity = busData['capacity'] ?? 0;
      final int currentPassengers = busData['current_passengers'] ?? 0;

      // 4. منع الحجز إذا كان الباص ممتلئاً
      if (currentPassengers >= capacity) {
        return 'full';
      }

      // 5. إضافة الحجز في جدول الحجوزات
      await Supabase.instance.client.from('reservations').insert({
        'user_id': userId,
        'bus_id': busId,
      });

      // 6. تحديث عدد الركاب الحاليين في جدول الباصات
      await Supabase.instance.client
          .from('buses')
          .update({'current_passengers': currentPassengers + 1})
          .eq('id', busId);

      return 'success';
    } catch (e) {
      print('🔥 خطأ أثناء عملية الحجز: $e');
      return 'error';
    }
  }

  // 🌟 دالة لمعرفة الباص الذي حجزه الطالب مسبقاً (إن وجد)
  Future<String?> getUserBookedBusId() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      // الاستعلام من جدول الحجوزات عن حجز هذا الطالب
      final existingReservations = await Supabase.instance.client
          .from('reservations')
          .select('bus_id')
          .eq('user_id', userId)
          .limit(1);

      if (existingReservations.isNotEmpty) {
        return existingReservations.first['bus_id'].toString();
      }
      return null; // إذا لم يقم بالحجز مسبقاً
    } catch (e) {
      print('🔥 خطأ في جلب حجز الطالب: $e');
      return null;
    }
  }

  // 🗑️ دالة إلغاء الحجز مع إرسال إشعار للمشرف
  Future<String> cancelReservation(String busId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 'error_not_logged_in';

      // 1. حذف الحجز
      await Supabase.instance.client
          .from('reservations')
          .delete()
          .eq('user_id', userId)
          .eq('bus_id', busId);

      // 2. جلب بيانات الباص
      final busData = await Supabase.instance.client
          .from('buses')
          .select('bus_number, current_passengers')
          .eq('id', busId)
          .single();

      final int currentPassengers = busData['current_passengers'] ?? 0;
      final String busNumber = busData['bus_number']?.toString() ?? 'غير محدد';

      // 3. إنقاص العداد
      final newCount = currentPassengers > 0 ? currentPassengers - 1 : 0;
      await Supabase.instance.client
          .from('buses')
          .update({'current_passengers': newCount})
          .eq('id', busId);

      // 4. 🌟 إرسال إشعار فوري للمشرف
      // جلب بيانات الطالب (افترضنا أن جدول الحسابات اسمه profiles وفيه name و university_id)
      final studentData = await Supabase.instance.client
          .from('profiles')
          .select(
            'name, university_id',
          ) // تأكد من أسماء الأعمدة في قاعدة بياناتك
          .eq('id', userId)
          .maybeSingle();

      final studentName = studentData?['name'] ?? 'طالب';
      final studentId = studentData?['university_id'] ?? 'غير معروف';

      final notificationMessage =
          'قام الطالب $studentName (رقم: $studentId) بإلغاء حجزه في باص رقم $busNumber. المقاعد المحجوزة الآن: $newCount';

      // إدراج الإشعار في جدول notifications كما في تصميم ER Diagram
      await Supabase.instance.client.from('notifications').insert({
        'type': 'cancellation',
        'message': notificationMessage,
        'date_time': DateTime.now().toIso8601String(),
        // 'user_id': supervisorId // (اختياري) إذا أردت توجيه الإشعار لمشرف محدد
      });

      return 'success';
    } catch (e) {
      print('🔥 خطأ أثناء إلغاء الحجز: $e');
      return 'error';
    }
  }
}
