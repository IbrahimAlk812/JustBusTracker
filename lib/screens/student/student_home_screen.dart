import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// واستدعاء مكتبة الصوت التي تستخدمها (مثال audioplayers إذا كنت تستخدمها)
import 'package:audioplayers/audioplayers.dart';

import 'package:just_bus_tracker/screens/student/bus_list_view_screen.dart';
import 'package:just_bus_tracker/screens/student/my_reservations_view.dart'; // 🌟 إضافة شاشة رحلتي
import 'package:just_bus_tracker/screens/student/bus_map_view.dart';
import 'package:just_bus_tracker/screens/student/student_complaints_screen.dart';
import 'package:just_bus_tracker/screens/student/student_profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  StreamSubscription? _complaintNotificationSubscription;

  // 🌟 ذاكرة لحفظ معرفات الشكاوى المحلولة مسبقاً لتجنب تكرار تنبيه الشكاوى القديمة عند الإقلاع
  final Set<String> _knownResolvedIds = {};
  bool _isFirstLoad = true;

  // 🌟 تم تحديث القائمة لتشمل 5 شاشات بالترتيب
  final List<Widget> _screens = [
    const BusListViewScreen(),
    const MyReservationsView(), // 🌟 الشاشة الجديدة كعنصر ثاني
    const StudentMapView(),
    const StudentComplaintsScreen(),
    const StudentProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startListeningToComplaintResolutions(); // 📡 تشغيل رادار استقبال حلول المشاكل فوراً
  }

  @override
  void dispose() {
    _complaintNotificationSubscription
        ?.cancel(); // إغلاق الرادار لحفظ موارد الهاتف
    super.dispose();
  }

  // 📡 دالة الرصد الحي لحل المشاكل والإشعار الصوتي
  void _startListeningToComplaintResolutions() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _complaintNotificationSubscription = Supabase.instance.client
        .from('complaints')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          for (var complaint in data) {
            final String id = complaint['id'].toString();
            final String status = complaint['status'] ?? 'pending';
            final String? adminResponse = complaint['admin_response'];

            if (status == 'resolved') {
              // إذا كان هذا التحميل الأول للتطبيق، نقوم فقط بحفظ الحالات القديمة بدون إزعاج المستخدم بالصوت
              if (_isFirstLoad) {
                _knownResolvedIds.add(id);
              } else {
                // 🔔 إذا تحولت الشكوى إلى محلولة حياً الآن ولم تكن معروفة مسبقاً: نطلق التنبيه!
                if (!_knownResolvedIds.contains(id)) {
                  _knownResolvedIds.add(id);
                  _triggerResolutionNotification(
                    adminResponse,
                  ); // إطلاق التنبيه والجمال البصري
                }
              }
            }
          }
          _isFirstLoad = false; // انتهاء التحميل الأول بنجاح
        });
  }

  // 🔔 دالة إطلاق الصوت والرسالة المنبثقة الاحترافية للطالب
  void _triggerResolutionNotification(String? adminResponse) {
    // 🎵 1. تشغيل الصوت فعلياً (تأكد من مسار ملف الصوت لديك)
    try {
      final player = AudioPlayer();
      player.play(
        AssetSource('sounds/alert.mp3'),
      ); // ضع اسم ملف الصوت الذي تستخدمه
    } catch (e) {
      debugPrint("خطأ في تشغيل الصوت: $e");
    }

    // 💬 2. إظهار رسالة منبثقة جذابة ومريحة في أسفل الشاشة
    String dialogMessage = adminResponse != null
        ? 'تم أخذ مشكلتك بعين الاعتبار وحلها بنجاح!\nالإجراء: $adminResponse'
        : 'تم أخذ مشكلتك بعين الاعتبار وحلها بنجاح من قبل الإدارة! 🛠️';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text(
              'تحديث بشأن بلاغك',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          dialogMessage,
          style: const TextStyle(fontSize: 15, height: 1.4),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسنًا',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF246BFD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF246BFD),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        // 🌟 إضافة التبويب الجديد ليكون مطابقاً لترتيب المصفوفة أعلاه
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'الباصات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number), // أيقونة التذكرة للرحلة
            label: 'رحلتي',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'التتبع'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'البلاغات',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
