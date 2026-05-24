import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentMapView extends StatefulWidget {
  const StudentMapView({Key? key}) : super(key: key);

  @override
  State<StudentMapView> createState() => _StudentMapViewState();
}

class _StudentMapViewState extends State<StudentMapView> {
  GoogleMapController? mapController;
  bool _hasLocationPermission = false;
  
  // مجموعة العلامات (Markers) التي ستظهر على الخريطة
  Set<Marker> _busMarkers = {};
  
  // للتحكم في الاتصال الحي بقاعدة البيانات (لإغلاقه عند الخروج من الشاشة)
  StreamSubscription? _busLocationsSubscription;

  // إحداثيات افتراضية (جامعة التكنو)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(32.4939, 35.9890), 
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
    _startListeningToBusLocations(); // تشغيل الرادار لجلب الباصات 📡
  }

  @override
  void dispose() {
    // إغلاق الاتصال عند الخروج من الشاشة لتوفير الموارد
    _busLocationsSubscription?.cancel();
    super.dispose();
  }

  // 1️⃣ دالة رصد مواقع الباصات الحية من Supabase
  void _startListeningToBusLocations() {
    _busLocationsSubscription = Supabase.instance.client
        .from('bus_locations') // تأكد أن هذا هو اسم جدول المواقع عندك
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      
      Set<Marker> newMarkers = {};
      
      for (var locationData in data) {
        // ⚠️ مهم: تأكد من أسماء الأعمدة في جدول bus_locations (مثلاً lat و lng)
        final double? lat = double.tryParse(locationData['latitude']?.toString() ?? '');
        final double? lng = double.tryParse(locationData['longitude']?.toString() ?? '');
        final String busId = locationData['bus_id']?.toString() ?? 'مجهول';

        if (lat != null && lng != null) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('bus_$busId'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: 'باص رقم $busId',
                snippet: 'متاح للحجز',
              ),
              // أيقونة زرقاء لتمييز الباص عن موقع الطالب
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), 
            ),
          );
        }
      }

      // تحديث الخريطة بالعلامات الجديدة
      if (mounted) {
        setState(() {
          _busMarkers = newMarkers;
        });
      }
    });
  }

  // 2️⃣ دالة تحديد موقع الطالب (النقطة الزرقاء)
  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    setState(() {
      _hasLocationPermission = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع مسار الباص', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: _hasLocationPermission, 
            myLocationButtonEnabled: _hasLocationPermission,
            zoomControlsEnabled: false,
            markers: _busMarkers, // عرض الباصات هنا 🚌
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),
          
          if (!_hasLocationPermission)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحديد موقعك...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}