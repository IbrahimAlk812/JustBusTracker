import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';

  // موقع افتراضي (مثلاً: عمان، الأردن) في حال لم تتوفر الصلاحيات فوراً
  static const LatLng _defaultLocation = LatLng(31.9522, 35.9150);

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndGetLocation();
  }

  // صلاحيات الموقع + جلب موقع الطالب الحالي
  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. التحقق من تفعيل خدمة الـ GPS في الهاتف
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'الرجاء تفعيل خدمة الموقع (GPS) في الهاتف.';
          _isLoading = false;
        });
        return;
      }

      // 2. التحقق من صلاحيات التطبيق
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // طلب الإذن من الطالب
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'تم رفض إذن الوصول للموقع.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'تم رفض الصلاحيات بشكل دائم. يرجى تفعيلها من إعدادات الهاتف.';
          _isLoading = false;
        });
        return;
      }

      // 3. جلب الموقع الحالي بنجاح
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // تحريك الكاميرا إلى موقع الطالب فور جلب الموقع
      _moveCameraToPosition(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء جلب الموقع: $e';
        _isLoading = false;
      });
    }
  }

  // دالة لتحريك الكاميرا بسلاسة
  void _moveCameraToPosition(LatLng target) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الباص'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // شاشة تحميل أثناء جلب الموقع
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          : Stack(
              children: [
                // واجهة خريطة جوجل واستبدال النص الثابت
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : _defaultLocation,
                    zoom: 15.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  // إظهار النقطة الزرقاء التي تمثل موقع الطالب الحالي
                  myLocationEnabled: true,
                  // إخفاء زر النقل التلقائي الافتراضي لخرائط جوجل لكي نتحكم به بأنفسنا
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),

                // زر عائم اختياري لإعادة تركيز الخريطة على موقع الطالب
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () {
                      if (_currentPosition != null) {
                        _moveCameraToPosition(
                          LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                        );
                      } else {
                        _checkLocationPermissionAndGetLocation();
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
