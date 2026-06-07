import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/student/bus_map_view.dart';
import 'package:just_bus_tracker/screens/auth/login_screen.dart'; // 🌟 أضفنا هذا المسار لطرد الطالب المحظور

class MyReservationsView extends StatefulWidget {
  const MyReservationsView({super.key});

  @override
  State<MyReservationsView> createState() => _MyReservationsViewState();
}

class _MyReservationsViewState extends State<MyReservationsView> {
  bool _isLoading = true;
  bool _isRequestingStop = false;
  bool _isCanceling = false;
  bool _isConfirmingBoarding = false;

  Map<String, dynamic>? _reservationData;
  Map<String, dynamic>? _busData;
  Map<String, dynamic>? _tripData;
  String _driverName = 'غير معروف';

  String _studentName = 'طالب';
  String _universityId = 'N/A';

  @override
  void initState() {
    super.initState();
    _fetchMyActiveReservation();
  }

  // 🌟 دالة جلب تاريخ اليوم باللغة العربية
  String _getTodayArabicDate() {
    final now = DateTime.now();
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final dayName = days[now.weekday - 1];
    return '$dayName ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchMyActiveReservation() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('name, university_id')
          .eq('id', user.id)
          .single();

      _studentName = profileRes['name'] ?? 'طالب';
      _universityId = profileRes['university_id']?.toString() ?? 'N/A';

      final res = await Supabase.instance.client
          .from('reservations')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'نشط')
          .maybeSingle();

      if (res != null) {
        _reservationData = res;
        final busId = res['bus_id'].toString();
        final tripId = res['trip_id'].toString();

        final bus = await Supabase.instance.client
            .from('buses')
            .select()
            .eq('id', busId)
            .single();
        _busData = bus;

        if (bus['driver_id'] != null) {
          final driver = await Supabase.instance.client
              .from('profiles')
              .select('name')
              .eq('id', bus['driver_id'])
              .maybeSingle();
          if (driver != null) _driverName = driver['name'].toString();
        }

        final trip = await Supabase.instance.client
            .from('trips')
            .select()
            .eq('id', tripId)
            .maybeSingle();
        _tripData = trip;
      }
    } catch (e) {
      debugPrint('Error fetching reservation: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmBoarding() async {
    if (_reservationData == null) return;
    setState(() => _isConfirmingBoarding = true);

    try {
      await Supabase.instance.client
          .from('reservations')
          .update({'has_boarded': true})
          .eq('id', _reservationData!['id']);

      setState(() {
        _reservationData!['has_boarded'] = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تأكيد صعودك للباص بنجاح! رحلة موفقة 🚌',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء التأكيد.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirmingBoarding = false);
    }
  }

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

  Future<void> _cancelReservation() async {
    if (_reservationData == null || _tripData == null) return;

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
              SizedBox(width: 10),
              Text(
                'تأكيد إلغاء الحجز',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد أنك تريد إلغاء حجزك؟\n\n'
            'ملاحظة: الإلغاء المتكرر يعرض حسابك للحظر المؤقت من النظام.',
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
      await Supabase.instance.client
          .from('reservations')
          .update({'status': 'ملغي'})
          .eq('id', _reservationData!['id']);

      final currentPassengers =
          int.tryParse(_tripData!['current_passengers'].toString()) ?? 1;
      final newPassengersCount = currentPassengers > 0
          ? currentPassengers - 1
          : 0;

      await Supabase.instance.client
          .from('trips')
          .update({'current_passengers': newPassengersCount})
          .eq('id', _tripData!['id']);

      // 🌟 نظام العقوبات: تسجيل المخالفة والطرد التلقائي للمخالفين
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('cancellation_warnings')
            .eq('id', user.id)
            .single();

        int warnings = profileRes['cancellation_warnings'] ?? 0;
        warnings += 1;
        bool shouldBan = warnings >= 3;

        await Supabase.instance.client
            .from('profiles')
            .update({'cancellation_warnings': warnings, 'is_banned': shouldBan})
            .eq('id', user.id);

        if (shouldBan && mounted) {
          // تسجيل الخروج فوراً وطرده لصفحة البداية
          await Supabase.instance.client.auth.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حظر حسابك لتجاوز الحد المسموح من الإلغاءات!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      setState(() {
        _reservationData = null;
        _busData = null;
        _tripData = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الحجز بنجاح.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
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
            'قم بحجز مقعدك من قائمة الرحلات المتاحة',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReservationView() {
    final String busNumber = _busData!['bus_number']?.toString() ?? 'N/A';
    final String route =
        _tripData?['route_name']?.toString() ?? 'مسار غير محدد';
    final String depTime =
        _tripData?['departure_time']?.toString() ?? 'غير محدد';
    final String boardingType =
        _reservationData!['boarding_type']?.toString() ?? 'المجمع';
    final String stationName =
        _reservationData!['station_name']?.toString() ?? '';
    final String boardingDisplay = boardingType == 'المجمع'
        ? 'المجمع'
        : 'محطة: $stationName';

    final bool hasBoarded = _reservationData!['has_boarded'] ?? false;

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
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        // 🌟 إضافة اليوم والتاريخ ومكان الركوب
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTicketInfo(
                              'اليوم والتاريخ',
                              _getTodayArabicDate(),
                            ),
                            _buildTicketInfo(
                              'نقطة الركوب',
                              boardingDisplay,
                              isRight: false,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTicketInfo('المسار', route),
                            _buildTicketInfo(
                              'وقت الانطلاق',
                              depTime,
                              isRight: false,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildTicketInfo('اسم السائق', _driverName),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            if (!hasBoarded)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isConfirmingBoarding ? null : _confirmBoarding,
                  icon: _isConfirmingBoarding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.how_to_reg, color: Colors.white),
                  label: const Text(
                    'تأكيد الصعود للباص ✔️',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'تم تأكيد الركوب بنجاح',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
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
                onPressed: (!hasBoarded || _isRequestingStop)
                    ? null
                    : _sendStopRequest,
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
                ),
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

            if (!hasBoarded)
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
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
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
