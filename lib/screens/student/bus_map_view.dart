import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui; // 🌟 محرك الرسم لإنشاء الأيقونات
import 'dart:typed_data'; // 🌟 للتعامل مع بيانات الصورة
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // 🌟 لتحميل صورة الأيقونة
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 🌟 استدعاء خدمة قاعدة البيانات لجلب الأرقام (تأكد من وجود هذا الملف)
import 'package:just_bus_tracker/services/database_service.dart';

class StudentMapView extends StatefulWidget {
  const StudentMapView({Key? key}) : super(key: key);

  @override
  State<StudentMapView> createState() => _StudentMapViewState();
}

class _StudentMapViewState extends State<StudentMapView> {
  GoogleMapController? mapController;
  bool _hasLocationPermission = false;

  Set<Marker> _busMarkers = {};
  final Map<String, LatLng> _previousBusLocations = {};
  final Map<String, double> _busBearings = {};
  StreamSubscription? _busLocationsSubscription;

  // 🌟 قاموس لحفظ أرقام الباصات الحقيقية لربطها بالـ UUID
  Map<String, String> _busNumbersMap = {};

  static const LatLng _technoUniversityLocation = LatLng(32.4939, 35.9890);

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
    // 🌟 أولاً نُحمّل أرقام الباصات، وبعد الانتهاء نُفعّل الرادار
    _loadAllBusNumbers().then((_) {
      _startListeningToBusLocations();
    });
  }

  // 🌟 دالة لجلب كل الباصات من قاعدة البيانات لمرة واحدة وحفظ أرقامها
  Future<void> _loadAllBusNumbers() async {
    try {
      // نفترض أن لديك دالة getBuses ترجع قائمة بالباصات
      final List<Map<String, dynamic>> buses = await DatabaseService()
          .getBuses();
      if (buses.isNotEmpty) {
        Map<String, String> tempMap = {};
        for (var bus in buses) {
          tempMap[bus['id'].toString()] =
              bus['bus_number']?.toString() ?? 'مجهول';
        }
        setState(() {
          _busNumbersMap = tempMap;
        });
      }
    } catch (e) {
      debugPrint("Error loading bus numbers: $e");
    }
  }

  @override
  void dispose() {
    _busLocationsSubscription?.cancel();
    super.dispose();
  }

  // 🎨 دالة هندسية محدثة: تدمج صورة الباص مع الرقم (بحجم مضاعف 2X)
  Future<BitmapDescriptor> _generateNumberedBusMarker(String busNumber) async {
    // 🌟 تمت مضاعفة أبعاد اللوحة بالكامل
    const double width = 360.0;
    const double height = 360.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 1. تحميل صورة الباص الأصلية
    final ByteData data = await rootBundle.load('assets/icons/bus_icon.png');
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      completer.complete(img);
    });
    final ui.Image busImage = await completer.future;

    // 2. رسم صورة الباص في الوسط بحجم مضاعف (من 130 إلى 260)
    const double imgSize = 260.0;
    paintImage(
      canvas: canvas,
      rect: const Rect.fromLTWH(
        (width - imgSize) / 2,
        (height - imgSize) / 2,
        imgSize,
        imgSize,
      ),
      image: busImage,
      fit: BoxFit.contain,
    );

    // 3. رسم لوحة خلف الرقم بحجم مضاعف
    const double labelWidth = 160.0;
    const double labelHeight = 70.0;
    final Paint labelPaint = Paint()..color = const Color(0xFF1A237E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          (width - labelWidth) / 2,
          0,
          labelWidth,
          labelHeight,
        ),
        const Radius.circular(15), // حواف دائرية أكثر نعومة
      ),
      labelPaint,
    );

    // 4. كتابة رقم الباص بخط مضاعف وعملاق (من 24 إلى 48)
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: busNumber,
      style: const TextStyle(
        fontSize: 48, // 🌟 خط ضخم جداً
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Arial',
      ),
    );
    textPainter.layout(minWidth: 0, maxWidth: labelWidth);

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (labelHeight - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lng1 = start.longitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double lng2 = end.longitude * math.pi / 180;
    final double dLng = lng2 - lng1;
    final double y = math.sin(dLng) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  void _startListeningToBusLocations() {
    _busLocationsSubscription = Supabase.instance.client
        .from('bus_locations')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) async {
          Set<Marker> newMarkers = {};

          for (var locationData in data) {
            final double? lat = double.tryParse(
              locationData['latitude']?.toString() ?? '',
            );
            final double? lng = double.tryParse(
              locationData['longitude']?.toString() ?? '',
            );
            final String busUuid =
                locationData['bus_id']?.toString() ?? 'مجهول'; // المعرف الطويل

            // 🌟 البحث عن رقم الباص الحقيقي بناءً على الـ UUID
            final String busNumber = _busNumbersMap[busUuid] ?? 'مجهول';

            if (lat != null && lng != null) {
              final LatLng newPosition = LatLng(lat, lng);
              double bearing = 0.0;

              if (_previousBusLocations.containsKey(busUuid)) {
                final oldPosition = _previousBusLocations[busUuid]!;
                if (oldPosition.latitude != newPosition.latitude ||
                    oldPosition.longitude != newPosition.longitude) {
                  bearing = _calculateBearing(oldPosition, newPosition);
                  _busBearings[busUuid] = bearing;
                } else {
                  bearing = _busBearings[busUuid] ?? 0.0;
                }
              }
              _previousBusLocations[busUuid] = newPosition;

              double distanceInKm =
                  Geolocator.distanceBetween(
                    lat,
                    lng,
                    _technoUniversityLocation.latitude,
                    _technoUniversityLocation.longitude,
                  ) /
                  1000;
              int etaMinutes = ((distanceInKm / 40) * 60).round();
              String etaString = etaMinutes <= 1
                  ? 'وصل تقريباً 🏁'
                  : '$etaMinutes دقيقة';

              // 🎨 جلب الأيقونة المدمجة (الباص + الرقم)
              BitmapDescriptor customIcon = await _generateNumberedBusMarker(
                busNumber,
              );

              newMarkers.add(
                Marker(
                  markerId: MarkerId('bus_$busUuid'),
                  position: newPosition,
                  infoWindow: InfoWindow(
                    title: 'باص رقم $busNumber', // 🌟 استخدام الرقم الحقيقي
                    snippet: 'الوصول المتوقع: $etaString',
                  ),
                  icon: customIcon, // 🌟 الأيقونة الجديدة المدمجة
                  rotation: bearing,
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                ),
              );
            }
          }

          if (mounted) {
            setState(() {
              _busMarkers = newMarkers;
            });
          }
        });
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
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
        desiredAccuracy: LocationAccuracy.high,
      );
      mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تتبع مسار الباص',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _technoUniversityLocation,
              zoom: 14.0,
            ),
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: _hasLocationPermission,
            zoomControlsEnabled: false,
            markers: _busMarkers,
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
                    Text(
                      'جاري تحديد موقعك...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
