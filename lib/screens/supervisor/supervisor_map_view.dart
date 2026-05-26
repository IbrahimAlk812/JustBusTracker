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

  // دالة رسم أيقونة الباص الضخمة (مكررة من خريطة الطالب)
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

    // 2. تتبع مواقع الطلاب النشطين
    _studentSubscription = Supabase.instance.client
        .from('student_locations')
        .stream(primaryKey: ['id'])
        .listen((studentData) {
          Set<Marker> currentMarkers = Set.from(
            _allMarkers.where((m) => !m.markerId.value.startsWith('stu_')),
          );

          for (var loc in studentData) {
            final double? lat = double.tryParse(
              loc['latitude']?.toString() ?? '',
            );
            final double? lng = double.tryParse(
              loc['longitude']?.toString() ?? '',
            );
            final String studentId = loc['user_id']?.toString() ?? '';

            if (lat != null && lng != null) {
              currentMarkers.add(
                Marker(
                  markerId: MarkerId('stu_$studentId'),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ), // أيقونة زرقاء للطالب
                  infoWindow: const InfoWindow(title: 'موقع طالب'),
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
