import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'supervisor_statistics_view.dart';
import 'supervisor_bus_table.dart';
import 'complaints_view.dart';
import 'supervisor_map_view.dart';
import 'package:just_bus_tracker/screens/supervisor/accounts_management_view.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;

  // إعدادات الرادار والصوت
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _lastNotificationId; // لمنع تكرار تشغيل الصوت لنفس الإشعار

  // 🌟 مصفوفة الواجهات بالترتيب الهندي الجديد والمطلوب 100%
  final List<Widget> _pages = [
    const SupervisorStatisticsView(), // Index 0: الإحصائيات
    const SupervisorBusTable(), // Index 1: الباصات
    const SupervisorMapView(), // Index 2: الخريطة
    const ComplaintsView(), // Index 3: الشكاوى
    const AccountsManagementView(), // Index 4: الحسابات (تتضمن حسابي بالداخل)
  ];

  @override
  void initState() {
    super.initState();
    // بدء تشغيل الرادار فور فتح واجهة المشرف
    _listenToCancellations();
  }

  // 📡 دالة الرادار: الاستماع الفوري لجدول الإشعارات في الخلفية
  void _listenToCancellations() {
    Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .order('date_time', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final latestNotification = data.first;
            final String currentNotificationId =
                latestNotification['notification_id']?.toString() ??
                latestNotification['id']?.toString() ??
                '';

            if (latestNotification['type'] == 'cancellation' &&
                currentNotificationId != _lastNotificationId) {
              _lastNotificationId = currentNotificationId;

              _playAlertSound(); // 🔊 تشغيل الصوت
              _showSupervisorAlert(
                latestNotification['message'] ?? '',
              ); // ⚠️ إظهار النافذة
            }
          }
        });
  }

  // 🔊 دالة تشغيل صوت التنبيه الآمنة
  Future<void> _playAlertSound() async {
    try {
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
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint("🔥 خطأ في تشغيل الصوت: $e");
    }
  }

  // ⚠️ دالة إظهار نافذة التنبيه المنسقة
  void _showSupervisorAlert(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
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
                textAlign: TextAlign.right,
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
              SizedBox(
                width: double.infinity,
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
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType
            .fixed, // يضمن ثبات وظهور الأيقونات الخمسة معاً
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF246BFD),
        unselectedItemColor: Colors.grey,
        // 🌟 ترتيب العناصر المطابق تماماً لترتيب المصفوفة بالأعلى
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'الإحصائيات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'الباصات',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'الخريطة'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'الشكاوى',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'الحسابات',
          ),
        ],
      ),
    );
  }
}
