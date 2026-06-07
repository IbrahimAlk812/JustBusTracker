import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorMapView extends StatefulWidget {
  const SupervisorMapView({Key? key}) : super(key: key);

  @override
  State<SupervisorMapView> createState() => _SupervisorMapViewState();
}

class _SupervisorMapViewState extends State<SupervisorMapView> {
  GoogleMapController? mapController;
  Set<Marker> _allMarkers = {};

  Map<String, String> _busNumbersMap = {};
  // 🌟 ذاكرة مؤقتة لحفظ أسماء الطلاب وتخفيف الضغط على السيرفر
  Map<String, String> _studentNamesMap = {};

  StreamSubscription? _busSubscription;
  StreamSubscription? _studentSubscription;

  static const LatLng _technoCenter = LatLng(32.4939, 35.9890);

  @override
  void initState() {
    super.initState();
    _loadAllBusNumbers().then((_) {
      _startTrackingEverything();
    });
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _studentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllBusNumbers() async {
    try {
      final response = await Supabase.instance.client
          .from('buses')
          .select('id, bus_number');
      Map<String, String> tempMap = {};
      for (var bus in response) {
        tempMap[bus['id'].toString()] =
            bus['bus_number']?.toString() ?? 'مجهول';
      }
      setState(() => _busNumbersMap = tempMap);
    } catch (e) {
      debugPrint("Error loading bus numbers: $e");
    }
  }

  // 🎨 دالة رسم أيقونة الباص الضخمة
  Future<BitmapDescriptor> _generateNumberedBusMarker(String busNumber) async {
    const double width = 360.0;
    const double height = 360.0;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final ByteData data = await rootBundle.load('assets/icons/bus_icon.png');
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(
      Uint8List.view(data.buffer),
      (ui.Image img) => completer.complete(img),
    );
    final ui.Image busImage = await completer.future;

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

    final Paint labelPaint = Paint()..color = const Color(0xFF246BFD);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH((width - 160) / 2, 0, 160, 70),
        const Radius.circular(15),
      ),
      labelPaint,
    );

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: busNumber,
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    textPainter.layout(minWidth: 0, maxWidth: 160);
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (70 - textPainter.height) / 2),
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

  // 🎨 الدالة الجديدة: رسم أيقونة الطالب
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  // 🎨 الدالة الجديدة الخاصة بك
  Future<BitmapDescriptor> _getStudentMarkerIcon() async {
    // تحميل صورتك من مجلد الـ assets، وضعنا حجم 120 لكي لا تظهر ضخمة جداً
    final Uint8List markerIcon = await _getBytesFromAsset(
      'assets/icons/student_icon.png',
      120,
    );
    return BitmapDescriptor.fromBytes(markerIcon);
  }

  void _startTrackingEverything() {
    // 1. تتبع الباصات
    _busSubscription = Supabase.instance.client
        .from('bus_locations')
        .stream(primaryKey: ['id'])
        .listen((busData) async {
          Set<Marker> currentMarkers = Set.from(
            _allMarkers.where((m) => !m.markerId.value.startsWith('bus_')),
          );

          for (var loc in busData) {
            final double? lat = double.tryParse(
              loc['latitude']?.toString() ?? '',
            );
            final double? lng = double.tryParse(
              loc['longitude']?.toString() ?? '',
            );
            final String busUuid = loc['bus_id']?.toString() ?? '';
            final String busNumber = _busNumbersMap[busUuid] ?? 'مجهول';

            if (lat != null && lng != null) {
              BitmapDescriptor customIcon = await _generateNumberedBusMarker(
                busNumber,
              );
              currentMarkers.add(
                Marker(
                  markerId: MarkerId('bus_$busUuid'),
                  position: LatLng(lat, lng),
                  icon: customIcon,
                  infoWindow: InfoWindow(title: 'باص رقم $busNumber'),
                ),
              );
            }
          }
          if (mounted) setState(() => _allMarkers = currentMarkers);
        });

    // 2. 🌟 تتبع مواقع الطلاب بناءً على الحجوزات النشطة
    _studentSubscription = Supabase.instance.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .listen((reservationData) async {
          Set<Marker> currentMarkers = Set.from(
            _allMarkers.where((m) => !m.markerId.value.startsWith('stu_')),
          );

          // جلب أيقونة الطالب مرة واحدة
          BitmapDescriptor studentIcon = await _getStudentMarkerIcon();

          // فلترة الحجوزات لتشمل فقط الحجوزات "النشطة"
          final activeReservations = reservationData.where(
            (res) => res['status'] == 'نشط',
          );

          for (var res in activeReservations) {
            final double? lat = double.tryParse(
              res['latitude']?.toString() ?? '',
            );
            final double? lng = double.tryParse(
              res['longitude']?.toString() ?? '',
            );
            final String studentId = res['user_id']?.toString() ?? '';
            final String stationName =
                res['station_name']?.toString() ?? 'محطة طريق';

            if (lat != null && lng != null) {
              // جلب اسم الطالب بذكاء للحفاظ على الأداء
              if (!_studentNamesMap.containsKey(studentId)) {
                try {
                  final profile = await Supabase.instance.client
                      .from('profiles')
                      .select('name')
                      .eq('id', studentId)
                      .maybeSingle();
                  _studentNamesMap[studentId] =
                      profile?['name']?.toString() ?? 'طالب';
                } catch (e) {
                  _studentNamesMap[studentId] = 'طالب';
                }
              }
              final studentName = _studentNamesMap[studentId];

              currentMarkers.add(
                Marker(
                  markerId: MarkerId('stu_${res['id']}'),
                  position: LatLng(lat, lng),
                  icon: studentIcon, // 🌟 استخدام الأيقونة الجديدة هنا
                  infoWindow: InfoWindow(
                    title: 'الراكب: $studentName',
                    snippet: 'المحطة: $stationName',
                  ),
                ),
              );
            }
          }
          if (mounted) setState(() => _allMarkers = currentMarkers);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المراقبة الجغرافية الشاملة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF246BFD),
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _technoCenter,
          zoom: 14.0,
        ),
        zoomControlsEnabled: false,
        markers: _allMarkers,
        onMapCreated: (controller) => mapController = controller,
      ),
    );
  }
}
