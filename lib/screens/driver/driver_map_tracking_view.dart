import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data'; // 🌟 إضافة مكتبة البيانات للصور
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🌟 لقراءة ملفات الـ assets
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class DriverMapTrackingView extends StatefulWidget {
  const DriverMapTrackingView({super.key});

  @override
  State<DriverMapTrackingView> createState() => _DriverMapTrackingViewState();
}

class _DriverMapTrackingViewState extends State<DriverMapTrackingView> {
  String? dynamicBusId;
  String? dynamicTripId; // 🌟 إضافة هذا المتغير لحفظ معرف الرحلة الحالية
  String driverName = 'جاري التحميل...';
  String busNumber = '...';
  String nextTripRoute = 'جاري البحث عن رحلات...';

  int totalCapacity = 0;
  int currentReservations = 0;
  int terminalReservations = 0;
  int stationReservations = 0;
  StreamSubscription? _reservationsSub;

  GoogleMapController? _mapController;
  bool _isTracking = false;
  bool _hasLocationPermission = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  StreamSubscription? _stopRequestsSub;
  final AudioPlayer _driverAudioPlayer = AudioPlayer();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(32.4939, 35.9890),
    zoom: 15.0,
  );

  Set<Marker> _studentMarkers = {};
  List<Map<String, dynamic>> _activeStudents = [];
  Map<String, String> _studentNamesCache = {};
  LatLng? _currentDriverPosition;

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
    _fetchDynamicDriverData();
  }

  Future<void> _fetchDynamicDriverData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .limit(1);
      final busRes = await Supabase.instance.client
          .from('buses')
          .select('id, bus_number, capacity')
          .eq('driver_id', userId)
          .limit(1);

      final String fetchedName = profileRes.isNotEmpty
          ? profileRes.first['name']
          : 'سائق غير معروف';

      if (busRes.isNotEmpty) {
        final bus = busRes.first;
        final bId = bus['id'].toString();

        // 🌟 تم إزالة .order('trip_date', ascending: true) وإزالة جلب عمود trip_date
        final tripRes = await Supabase.instance.client
            .from('trips')
            .select('id, route_name, departure_time')
            .eq('bus_id', bId)
            .eq('status', 'مجدولة')
            .order('departure_time', ascending: true)
            .limit(1);

        if (mounted) {
          setState(() {
            dynamicBusId = bId;
            driverName = fetchedName;
            busNumber = bus['bus_number'].toString();
            totalCapacity =
                int.tryParse(bus['capacity']?.toString() ?? '0') ?? 0;
            if (tripRes.isNotEmpty) {
              dynamicTripId = tripRes.first['id']
                  .toString(); // 🌟 حفظ معرف الرحلة
              nextTripRoute = tripRes.first['route_name'];
            } else {
              dynamicTripId = null;
              nextTripRoute = 'لا يوجد مسار مجدول';
            }
          });
        }

        _startListeningToStopRequests(bId);
        if (dynamicTripId != null) {
          _startListeningToReservations(
            dynamicTripId!,
          ); // 🌟 نستمع لحجوزات هذه الرحلة فقط
        }
      } else {
        if (mounted) {
          setState(() {
            driverName = fetchedName;
            nextTripRoute = 'غير مرتبط بباص حالياً';
            busNumber = '...';
          });
        }
      }
    } catch (e) {
      debugPrint('🔥 خطأ في جلب بيانات السائق الحية: $e');
    }
  }

  Future<String> _getStudentName(String userId) async {
    if (_studentNamesCache.containsKey(userId)) {
      return _studentNamesCache[userId]!;
    }
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      final name = res != null ? res['name'].toString() : 'طالب';
      _studentNamesCache[userId] = name;
      return name;
    } catch (e) {
      return 'طالب';
    }
  }

  // 🌟 دالة مساعدة لتحميل الصورة وتصغير حجمها
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

  // 🎨 الدالة الخاصة بجلب أيقونة الطالب المخصصة
  Future<BitmapDescriptor> _getStudentMarkerIcon() async {
    final Uint8List markerIcon = await _getBytesFromAsset(
      'assets/icons/student_icon.png',
      120,
    );
    return BitmapDescriptor.fromBytes(markerIcon);
  }

  // 🌟 دالة تحديث دبابيس الطلاب وحساب المسافة
  Future<void> _updateStudentMarkers() async {
    Set<Marker> newMarkers = {};

    // جلب الأيقونة المخصصة مرة واحدة
    BitmapDescriptor studentIcon = await _getStudentMarkerIcon();

    for (var req in _activeStudents) {
      if (req['latitude'] != null && req['longitude'] != null) {
        final lat = double.tryParse(req['latitude'].toString());
        final lng = double.tryParse(req['longitude'].toString());
        if (lat != null && lng != null) {
          String sName = await _getStudentName(req['user_id'].toString());

          String distanceText = '';
          if (_currentDriverPosition != null) {
            double dist = Geolocator.distanceBetween(
              lat,
              lng,
              _currentDriverPosition!.latitude,
              _currentDriverPosition!.longitude,
            );
            distanceText = dist > 1000
                ? '${(dist / 1000).toStringAsFixed(1)} كم'
                : '${dist.round()} متر';
          }

          newMarkers.add(
            Marker(
              markerId: MarkerId('student_${req['id']}'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: 'الراكب: $sName',
                snippet: distanceText.isNotEmpty
                    ? 'يبعد عنك: $distanceText'
                    : 'المحطة: ${req['station_name']}',
              ),
              icon: studentIcon, // 🌟 استخدام الأيقونة المخصصة هنا
            ),
          );
        }
      }
    }
    if (mounted) setState(() => _studentMarkers = newMarkers);
  }

  void _startListeningToReservations(String theBusId) {
    _reservationsSub = Supabase.instance.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .eq('trip_id', theBusId)
        .listen((data) {
          final activeReqs = data
              .where((req) => req['status'] == 'نشط')
              .toList();
          int tCount = activeReqs
              .where((req) => req['boarding_type'] == 'المجمع')
              .length;
          int sCount = activeReqs
              .where((req) => req['boarding_type'] == 'محطة طريق')
              .length;

          if (mounted) {
            setState(() {
              currentReservations = activeReqs.length;
              terminalReservations = tCount;
              stationReservations = sCount;
              _activeStudents = activeReqs;
            });
            _updateStudentMarkers();
          }
        });
  }

  void _startListeningToStopRequests(String theBusId) {
    _stopRequestsSub = Supabase.instance.client
        .from('stop_requests')
        .stream(primaryKey: ['id'])
        .eq('bus_id', theBusId)
        .listen((List<Map<String, dynamic>> data) {
          final activeRequests = data
              .where((req) => req['is_handled'] == false)
              .toList();
          if (activeRequests.isNotEmpty) {
            final request = activeRequests.first;
            _playStopBellSound();
            _showStopAlertToDriver(
              request['id'],
              request['student_name'] ?? 'طالب',
            );
          }
        });
  }

  Future<void> _playStopBellSound() async {
    try {
      await _driverAudioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint("🔥 خطأ في تشغيل صوت تنبيه السائق: $e");
    }
  }

  void _showStopAlertToDriver(dynamic requestId, String studentName) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Navigator.pop(context);
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

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('الرجاء تفعيل خدمة الموقع (GPS)', isError: true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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
      _currentDriverPosition = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentDriverPosition!),
      );
    } catch (e) {
      debugPrint("Error get initial location: $e");
    }
  }

  void _startTracking() {
    if (!_hasLocationPermission) {
      _showSnackBar('صلاحيات الموقع غير مفعلة', isError: true);
      return;
    }
    if (dynamicBusId == null) {
      _showSnackBar('لا يوجد باص مرتبط بحسابك لبدء الرحلة!', isError: true);
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
              _currentDriverPosition = LatLng(
                position.latitude,
                position.longitude,
              );
              _updateStudentMarkers();
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(_currentDriverPosition!),
              );

              try {
                await Supabase.instance.client.from('bus_locations').upsert({
                  'bus_id': dynamicBusId!,
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                });
              } catch (e) {
                debugPrint('خطأ في تحديث الموقع: $e');
              }
            }
          },
        );
  }

  void _confirmEndTrip() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'إنهاء الرحلة وتفريغ الباص',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد أنك وصلت لنهاية المسار وتريد إنهاء الرحلة؟\n\n'
            'سيتم تحويل جميع الحجوزات النشطة في هذه الرحلة إلى "مكتملة"، وسيتم تصفير عداد كراسي الباص للرحلة القادمة.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'تراجع',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _endTripAndClearBus();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'نعم، إنهاء وتفريغ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 الدالة العبقرية لإدارة دورة حياة الرحلة ومعاقبة المتغيبين
  Future<void> _endTripAndClearBus() async {
    _showSnackBar('جاري إنهاء الرحلة وتطبيق نظام الحضور...', isError: false);
    _positionStreamSubscription?.cancel();
    setState(() => _isTracking = false);

    try {
      if (dynamicTripId != null) {
        // 1. جلب جميع الحجوزات النشطة لهذه الرحلة فقط
        final activeRes = await Supabase.instance.client
            .from('reservations')
            .select('id, user_id, has_boarded')
            .eq('trip_id', dynamicTripId!)
            .eq('status', 'نشط');

        // 2. محاسبة الطلاب
        for (var res in activeRes) {
          bool boarded = res['has_boarded'] ?? false;
          String resId = res['id'].toString();
          String studentId = res['user_id'].toString();

          if (boarded) {
            // طالب ملتزم -> نجاح الرحلة
            await Supabase.instance.client
                .from('reservations')
                .update({'status': 'مكتمل'})
                .eq('id', resId);
          } else {
            // 🚨 طالب متغيب (No-Show) -> غياب + إنذار
            await Supabase.instance.client
                .from('reservations')
                .update({'status': 'غياب'})
                .eq('id', resId);

            // جلب إنذارات الطالب وزيادتها
            final studentProfile = await Supabase.instance.client
                .from('profiles')
                .select('no_show_warnings')
                .eq('id', studentId)
                .single();
            int currentWarnings = studentProfile['no_show_warnings'] ?? 0;
            int newWarnings = currentWarnings + 1;
            bool shouldBan =
                newWarnings >= 3; // 🌟 الحظر التلقائي بعد 3 إنذارات

            await Supabase.instance.client
                .from('profiles')
                .update({
                  'no_show_warnings': newWarnings,
                  'is_banned': shouldBan,
                })
                .eq('id', studentId);
          }
        }

        // 3. إنهاء الرحلة فعلياً في النظام
        await Supabase.instance.client
            .from('trips')
            .update({'status': 'مكتملة'})
            .eq('id', dynamicTripId!);

        _showSnackBar(
          'تم إنهاء الرحلة بنجاح! تم تسجيل الحضور والمخالفات.',
          isError: false,
        );
        _fetchDynamicDriverData(); // 🌟 تحديث الواجهة لجلب الرحلة التالية إن وجدت
      }
    } catch (e) {
      debugPrint('Error ending trip: $e');
      _showSnackBar('حدث خطأ أثناء إنهاء الرحلة.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _stopRequestsSub?.cancel();
    _reservationsSub?.cancel();
    _driverAudioPlayer.dispose();
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
            markers: _studentMarkers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF246BFD),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'السائق: $driverName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF246BFD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'باص: $busNumber',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 15),
                          Row(
                            children: [
                              const Icon(
                                Icons.route,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'المسار: $nextTripRoute',
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'حالة الحجوزات:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                '$currentReservations / $totalCapacity مقعد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: currentReservations >= totalCapacity
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: totalCapacity > 0
                                  ? currentReservations / totalCapacity
                                  : 0,
                              backgroundColor: Colors.orange.shade100,
                              color: currentReservations >= totalCapacity
                                  ? Colors.red
                                  : Colors.orange,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                '🏢 من المجمع: $terminalReservations',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 15,
                                color: Colors.grey.shade400,
                              ),
                              Text(
                                '🚏 محطات الطريق: $stationReservations',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                            color: _isTracking
                                ? Colors.green
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isTracking
                            ? _confirmEndTrip
                            : _startTracking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTracking
                              ? Colors.red
                              : const Color(0xFF246BFD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isTracking
                              ? 'إنهاء الرحلة وتفريغ الباص'
                              : 'بدء الرحلة ($nextTripRoute)',
                          style: const TextStyle(
                            fontSize: 17,
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
          ),
        ],
      ),
    );
  }
}
