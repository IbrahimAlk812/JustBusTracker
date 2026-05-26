import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // 🌟 استدعاء مكتبة الصوت للإنذار

class DriverMapTrackingView extends StatefulWidget {
  const DriverMapTrackingView({super.key});

  @override
  State<DriverMapTrackingView> createState() => _DriverMapTrackingViewState();
}

class _DriverMapTrackingViewState extends State<DriverMapTrackingView> {
  // ⚠️ نستخدم UUID الباص للتجربة (يُفضل لاحقاً جلبه من بيانات السائق المسجلة)
  final String busId = '317bdd6f-0e79-4578-8cd2-0acdc2214176';

  GoogleMapController? _mapController;
  bool _isTracking = false;
  bool _hasLocationPermission = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  // 🌟 متغيرات رادار طلبات النزول الجديدة
  StreamSubscription? _stopRequestsSub;
  final AudioPlayer _driverAudioPlayer = AudioPlayer();

  // إحداثيات افتراضية (جامعة التكنو) حتى يتم تحديد الموقع
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(32.4939, 35.9890),
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
    _startListeningToStopRequests(); // 🌟 تشغيل رادار استقبال طلبات النزول فوراً عند تشغيل الشاشة
  }

  // 📡 دالة الرادار الحية: تستمع للطلبات الخاصة بهذا الباص
  void _startListeningToStopRequests() {
    _stopRequestsSub = Supabase.instance.client
        .from('stop_requests')
        .stream(primaryKey: ['id'])
        .eq(
          'bus_id',
          busId,
        ) // 🌟 نستدعي فلتر واحد فقط للاتصال (قيد في Supabase)
        .listen((List<Map<String, dynamic>> data) {
          // 🌟 نقوم بالفلترة الثانية (للطلبات غير المعالجة) برمجياً هنا
          final activeRequests = data
              .where((req) => req['is_handled'] == false)
              .toList();

          if (activeRequests.isNotEmpty) {
            final request = activeRequests.first;
            _playStopBellSound(); // 🔊 إطلاق الجرس
            _showStopAlertToDriver(
              request['id'],
              request['student_name'] ?? 'طالب',
            ); // 🛑 إظهار الشاشة الحمراء
          }
        });
  }

  // 🔊 دالة تشغيل جرس التنبيه في هاتف السائق
  Future<void> _playStopBellSound() async {
    try {
      await _driverAudioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint("🔥 خطأ في تشغيل صوت تنبيه السائق: $e");
    }
  }

  // 🛑 دالة بناء نافذة طلب النزول المنبثقة والمنسقة بالكامل للسائق
  void _showStopAlertToDriver(dynamic requestId, String studentName) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible:
          false, // إجبار السائق على التفاعل مع النافذة لسلامة الركاب
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.pan_tool, color: Colors.red.shade700, size: 35),
              const SizedBox(width: 10),
              const Text(
                'طلب توقف فوري!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            'الطالب ($studentName) يطلب النزول الآن في المحطة القادمة.',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
                onPressed: () async {
                  Navigator.pop(context); // إغلاق النافذة

                  // تحديث حالة الطلب في قاعدة البيانات إلى تمت المعالجة (is_handled = true) لكي تختفي
                  await Supabase.instance.client
                      .from('stop_requests')
                      .update({'is_handled': true})
                      .eq('id', requestId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'علم، سأتوقف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛡️ فحص صلاحيات الموقع وتحديد المكان الأولي
  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('الرجاء تفعيل خدمة الموقع (GPS)', isError: true);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('تم رفض صلاحيات الموقع', isError: true);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'صلاحيات الموقع مرفوضة نهائياً من الإعدادات',
        isError: true,
      );
      return;
    }

    setState(() {
      _hasLocationPermission = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      debugPrint("Error get initial location: $e");
    }
  }

  // 📡 بدء بث الموقع (بدء الرحلة)
  void _startTracking() {
    if (!_hasLocationPermission) {
      _showSnackBar('صلاحيات الموقع غير مفعلة', isError: true);
      return;
    }

    setState(() {
      _isTracking = true;
    });

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position? position) async {
            if (position != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(position.latitude, position.longitude),
                ),
              );

              try {
                await Supabase.instance.client
                    .from('bus_locations')
                    .update({
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                    })
                    .eq('bus_id', busId);
              } catch (e) {
                debugPrint('خطأ في تحديث الموقع: $e');
              }
            }
          },
        );
  }

  // 🛑 إيقاف البث (إنهاء الرحلة)
  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isTracking = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _stopRequestsSub
        ?.cancel(); // 🌟 إغلاق رادار استماع طلبات النزول لحفظ موارد الهاتف
    _driverAudioPlayer.dispose(); // 🌟 تفريغ مشغل الصوت من الذاكرة تماماً
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الرحلة الحالية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF246BFD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTracking ? Icons.radar : Icons.location_off,
                        color: _isTracking ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isTracking
                            ? 'يتم الآن بث الموقع مباشرة'
                            : 'نظام التتبع متوقف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isTracking ? Colors.green : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isTracking ? _stopTracking : _startTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking
                            ? Colors.red
                            : const Color(0xFF246BFD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isTracking ? 'إنهاء الرحلة' : 'بدء الرحلة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
