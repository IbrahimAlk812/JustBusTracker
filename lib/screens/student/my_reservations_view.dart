import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/student/bus_map_view.dart'; // 🌟 تفعيل مسار شاشة الخريطة

class MyReservationsView extends StatefulWidget {
  const MyReservationsView({super.key});

  @override
  State<MyReservationsView> createState() => _MyReservationsViewState();
}

class _MyReservationsViewState extends State<MyReservationsView> {
  bool _isLoading = true;
  bool _isRequestingStop = false;
  bool _isCanceling = false;

  Map<String, dynamic>? _reservationData;
  Map<String, dynamic>? _busData;
  String _studentName = 'طالب';
  String _universityId = 'N/A'; // 🌟 متغير جديد لحفظ الرقم الجامعي

  @override
  void initState() {
    super.initState();
    _fetchMyActiveReservation();
  }

  // 1. جلب بيانات الحجز النشط للطالب
  Future<void> _fetchMyActiveReservation() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // جلب اسم الطالب ورقم الجامعة من جدول الـ profiles
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('name, university_id') // 🌟 جلب الحقلين معاً
          .eq('id', user.id)
          .single();

      _studentName = profileRes['name'] ?? 'طالب';
      _universityId = profileRes['university_id']?.toString() ?? 'N/A';

      // جلب الحجز الفعال (نشط)
      final res = await Supabase.instance.client
          .from('reservations')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'نشط')
          .maybeSingle();

      if (res != null) {
        _reservationData = res;
        // جلب بيانات الباص المرتبط بهذا الحجز
        final bus = await Supabase.instance.client
            .from('buses')
            .select()
            .eq('id', res['bus_id'])
            .single();
        _busData = bus;
      }
    } catch (e) {
      debugPrint('Error fetching reservation: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. دالة طلب النزول
  Future<void> _sendStopRequest() async {
    if (_busData == null) return;
    setState(() => _isRequestingStop = true);

    try {
      await Supabase.instance.client.from('stop_requests').insert({
        'bus_id': _busData!['id'],
        'student_name': _studentName,
        'is_handled': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تنبيه السائق بنجاح! 🛑 سيتم التوقف في المحطة القادمة.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إرسال الطلب.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRequestingStop = false);
    }
  }

  // 3. دالة إلغاء الحجز
  Future<void> _cancelReservation() async {
    if (_reservationData == null || _busData == null) return;

    // 🌟 تحديث نص نافذة التأكيد ليطابق واجهة الباصات تماماً
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              Text(
                'تأكيد إلغاء الحجز',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد أنك تريد إلغاء حجزك؟\n\n'
            'ملاحظة: الإلغاء المتكرر أو الإلغاء المتأخر قد يعرض حسابك للحظر المؤقت من الحجز للحفاظ على حقوق الطلبة الآخرين.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'نعم، قم بالإلغاء',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isCanceling = true);
    try {
      // تغيير حالة الحجز بقاعدة البيانات إلى ملغي
      await Supabase.instance.client
          .from('reservations')
          .update({'status': 'ملغي'})
          .eq('id', _reservationData!['id']);

      // إنقاص عدد الركاب في الباص
      final currentPassengers =
          int.tryParse(_busData!['current_passengers'].toString()) ?? 1;
      final newPassengersCount = currentPassengers > 0
          ? currentPassengers - 1
          : 0;

      await Supabase.instance.client
          .from('buses')
          .update({'current_passengers': newPassengersCount})
          .eq('id', _busData!['id']);

      setState(() {
        _reservationData = null;
        _busData = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الحجز بنجاح.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('Error canceling: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء الإلغاء.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCanceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'تذكرة الرحلة',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservationData == null || _busData == null
          ? _buildNoReservationView()
          : _buildActiveReservationView(),
    );
  }

  Widget _buildNoReservationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_filled_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'لا يوجد لديك حجوزات نشطة حالياً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'قم بحجز مقعدك من قائمة الباصات المتاحة',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReservationView() {
    final String busNumber = _busData!['bus_number']?.toString() ?? 'N/A';
    final String route = _busData!['route']?.toString() ?? 'مسار غير محدد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF246BFD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 30,
                        ),
                        Text(
                          'باص رقم: $busNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTicketInfo('الراكب', _studentName),
                            _buildTicketInfo(
                              'الرقم الجامعي',
                              _universityId,
                              isRight: false,
                            ), // 🌟 تم استبداله بالرقم الجامعي هنا
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTicketInfo('المسار', route),
                            _buildTicketInfo(
                              'الحالة',
                              'مؤكد 🟢',
                              isRight: false,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ), // 🌟 تم التخلص من خطوط الباركود المتقطعة والـ QR بالكامل لتبقى التذكرة نظيفة ومبسطة
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // 🌟 تفعيل التوجيه لشاشة الخريطة الحية مباشرة عند الضغط
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentMapView(),
                    ),
                  );
                },
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text(
                  'تتبع الباص على الخريطة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isRequestingStop ? null : _sendStopRequest,
                icon: _isRequestingStop
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.pan_tool, color: Colors.white),
                label: const Text(
                  'طلب النزول الآن 🛑',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ), // 🌟 تعديل النص المطلوبة
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (_isCanceling)
              const Center(child: CircularProgressIndicator())
            else
              TextButton.icon(
                onPressed: _cancelReservation,
                icon: const Icon(Icons.cancel, color: Colors.grey),
                label: const Text(
                  'إلغاء الحجز',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfo(String title, String value, {bool isRight = true}) {
    return Column(
      crossAxisAlignment: isRight
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
