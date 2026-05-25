import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🌟 إضافة استدعاء سوبابيس
import 'package:audioplayers/audioplayers.dart'; // 🌟 إضافة استدعاء مكتبة الصوت
import 'supervisor_statistics_view.dart';
import 'supervisor_bus_table.dart';
import 'complaints_view.dart';
import 'package:just_bus_tracker/screens/supervisor/accounts_management_view.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_map_view.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;

  // 🌟 إعدادات الرادار والصوت الجديدة
  final AudioPlayer _audioPlayer = AudioPlayer();
  String?
  _lastNotificationId; // لمنع تكرار تشغيل الصوت لنفس الإشعار عند تحديث الشاشة

  // 🌟 قائمة الشاشات (تم إضافة شاشة إدارة الحسابات كعنصر رابع هنا)
  final List<Widget> _pages = [
    const SupervisorStatisticsView(),
    const SupervisorBusTable(),
    const ComplaintsView(),
    const AccountsManagementView(),
    const SupervisorMapView(), // الشاشة الخامسة
  ];

  @override
  void initState() {
    super.initState();
    // 🌟 بدء تشغيل الرادار فور فتح واجهة المشرف
    _listenToCancellations();
  }

  // 📡 دالة الرادار: الاستماع الفوري لجدول الإشعارات في الخلفية
  void _listenToCancellations() {
    Supabase.instance.client
        .from('notifications')
        .stream(
          primaryKey: ['notification_id'],
        ) // ⚠️ إذا كان اسم المفتاح الأساسي للجدول في سوبابيس هو id فقط قم بتغييرها لـ ['id']
        .order('date_time', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final latestNotification = data.first;
            // جلب معرّف الإشعار الحالي
            final String currentNotificationId =
                latestNotification['notification_id']?.toString() ??
                latestNotification['id']?.toString() ??
                '';

            // التحقق من نوع الإشعار، والتأكد من أنه إشعار جديد لم نقم بالتنبيه عليه قبل ثوانٍ
            if (latestNotification['type'] == 'cancellation' &&
                currentNotificationId != _lastNotificationId) {
              _lastNotificationId =
                  currentNotificationId; // توثيق الإشعار لمنع التكرار

              _playAlertSound(); // 🔊 تشغيل الصوت
              _showSupervisorAlert(
                latestNotification['message'] ?? '',
              ); // ⚠️ إظهار النافذة
            }
          }
        });
  }

  // 🔊 دالة تشغيل صوت التنبيه المحدثة والآمنة
  Future<void> _playAlertSound() async {
    try {
      // إجبار المحرك على تهيئة الصوت كمادة تنبيه قوية
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.notificationEvent,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(),
        ),
      );

      // تشغيل الملف من المجلد المحلي
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint("🔥 خطأ في تشغيل الصوت: $e");
    }
  }

  // ⚠️ دالة إظهار نافذة التنبيه المنسقة والاحترافية
  void _showSupervisorAlert(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // إجبار المشرف على الضغط على الزر
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection
              .rtl, // إجبار النافذة بالكامل على الاتجاه العربي الصحيح
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notification_important,
                    color: Colors.red.shade700,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تنبيه حركي فوري',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            content: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                message,
                textAlign: TextAlign.right, // محاذاة النص لليمين
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            actions: [
              Spacer(),
              SizedBox(
                width: double.infinity, // جعل الزر ممتداً ليسهل النقر عليه
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'تم الاستلام والمتابعة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer
        .dispose(); // 🌟 إغلاق محرك الصوت بأمان عند الخروج من التطبيق لتجنب تسريب الذاكرة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // مهم جداً عشان تظهر الأيقونات
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'الإحصائيات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'الباصات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'الشكاوى',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'الحسابات',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'الخريطة'),
        ],
      ),
    );
  }
}
