import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverScreen extends StatefulWidget {
  // المعرّف الخاص بباص السائق (يمكن تمريره عند تسجيل الدخول)
  // وضعنا UUID الباص B-101 كمثال للتجربة الفورية
  final String busId = '317bdd6f-0e79-4578-8cd2-0acdc2214176';

  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  // 🛡️ دالة فحص الصلاحيات وطلبها
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('الرجاء تفعيل خدمة الموقع (GPS)', isError: true);
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('تم رفض صلاحيات الموقع', isError: true);
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'صلاحيات الموقع مرفوضة نهائياً من إعدادات الهاتف',
        isError: true,
      );
      return false;
    }
    return true;
  }

  // 📡 دالة بدء بث الموقع (بدء الرحلة)
  Future<void> _startTracking() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() {
      _isTracking = true;
    });

    // إعدادات الـ GPS: تحديث الموقع كلما تحرك السائق 10 أمتار
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position? position) async {
          if (position != null) {
            // إرسال الإحداثيات الجديدة إلى Supabase في الخلفية
            try {
              await Supabase.instance.client
                  .from('bus_locations')
                  .update({
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                  })
                  .eq(
                    'bus_id',
                    widget.busId,
                  ); // تحديث سطر الباص الخاص بهذا السائق

              debugPrint(
                'تم تحديث الموقع: ${position.latitude}, ${position.longitude}',
              );
            } catch (e) {
              debugPrint('خطأ في إرسال الموقع: $e');
            }
          }
        });
  }

  // 🛑 دالة إيقاف البث (إنهاء الرحلة)
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
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'لوحة قيادة السائق',
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة توضح حالة الاتصال
            Icon(
              _isTracking ? Icons.radar : Icons.location_off,
              size: 100,
              color: _isTracking ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              _isTracking
                  ? 'يتم الآن بث الموقع للطلاب...'
                  : 'نظام التتبع متوقف',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isTracking ? Colors.green : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 50),

            // زر البداية والنهاية الكبير
            GestureDetector(
              onTap: _isTracking ? _stopTracking : _startTracking,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTracking ? Colors.red : const Color(0xFF246BFD),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isTracking ? Colors.red : const Color(0xFF246BFD))
                              .withOpacity(0.4),
                      spreadRadius: 10,
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _isTracking ? 'إنهاء الرحلة' : 'بدء الرحلة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
