import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/services/database_service.dart';

class BusListViewScreen extends StatefulWidget {
  const BusListViewScreen({super.key});

  @override
  State<BusListViewScreen> createState() => _BusListViewScreenState();
}

class _BusListViewScreenState extends State<BusListViewScreen> {
  final DatabaseService _dbService = DatabaseService();

  late Future<List<Map<String, dynamic>>> _tripsFuture;
  String? _bookedTripId; // 🌟 أصبحنا نعتمد على معرف الرحلة بدلاً من الباص

  Map<String, String> _busEtas = {};
  StreamSubscription? _etaSubscription;
  StreamSubscription? _reservationSubscription;

  Position? _myLocation;
  List<Map<String, dynamic>> _stationsList = [];
  static const double technoLat = 32.4939;
  static const double technoLng = 35.9890;

  @override
  void initState() {
    super.initState();
    _refreshTrips();
    _startListeningToUserReservation();
    _fetchStations();
    _fetchMyLocation();
  }

  Future<void> _fetchMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (mounted) {
      setState(() => _myLocation = position);
      _startListeningToETAs();
    }
  }

  Future<void> _fetchStations() async {
    try {
      final data = await Supabase.instance.client.from('stations').select();
      if (mounted)
        setState(() => _stationsList = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('🔥 خطأ في جلب المحطات: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTodayTripsData() async {
    final now = DateTime.now();
    final todayString =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final client = Supabase.instance.client;

    try {
      // 🌟 تم إزالة .eq('trip_date', todayString) لأن الرحلات أصبحت ثابتة
      final trips = await client
          .from('trips')
          .select()
          .eq('status', 'مجدولة')
          .order('departure_time', ascending: true);
      final buses = await client.from('buses').select();
      final drivers = await client
          .from('profiles')
          .select('id, name')
          .eq('role', 'driver');

      List<Map<String, dynamic>> mergedTrips = [];

      for (var trip in trips) {
        final bus = buses.firstWhere(
          (b) => b['id'].toString() == trip['bus_id'].toString(),
          orElse: () => <String, dynamic>{},
        );
        if (bus.isNotEmpty) {
          final driverId = bus['driver_id']?.toString();
          String driverName = 'غير معيّن';
          if (driverId != null) {
            final driver = drivers.firstWhere(
              (d) => d['id'].toString() == driverId,
              orElse: () => <String, dynamic>{},
            );
            if (driver.isNotEmpty) driverName = driver['name'].toString();
          }

          mergedTrips.add({
            'trip_id': trip['id'].toString(),
            'bus_id': bus['id'].toString(),
            'bus_number': bus['bus_number'].toString(),
            'driver_name': driverName,
            'route_name': trip['route_name'].toString(),
            'departure_time': trip['departure_time'].toString(),
            'capacity': int.tryParse(bus['capacity']?.toString() ?? '0') ?? 0,
            'current_passengers':
                int.tryParse(trip['current_passengers']?.toString() ?? '0') ??
                0, // 🌟 يقرأ من الرحلة
          });
        }
      }
      return mergedTrips;
    } catch (e) {
      debugPrint('Error fetching trips: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _etaSubscription?.cancel();
    _reservationSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToUserReservation() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _reservationSubscription = Supabase.instance.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          final activeResList = data
              .where((res) => res['status'] == 'نشط')
              .toList();
          if (mounted) {
            setState(() {
              if (activeResList.isNotEmpty) {
                _bookedTripId = activeResList.first['trip_id']
                    ?.toString(); // 🌟 الاعتماد على معرف الرحلة
              } else {
                _bookedTripId = null;
              }
            });
          }
        });
  }

  void _startListeningToETAs() {
    if (_myLocation == null) return;

    _etaSubscription = Supabase.instance.client
        .from('bus_locations')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          Map<String, String> updatedEtas = {};
          for (var loc in data) {
            final String busId = loc['bus_id']?.toString() ?? '';
            final double? lat = double.tryParse(
              loc['latitude']?.toString() ?? '',
            );
            final double? lng = double.tryParse(
              loc['longitude']?.toString() ?? '',
            );

            if (busId.isNotEmpty && lat != null && lng != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                lat,
                lng,
                _myLocation!.latitude,
                _myLocation!.longitude,
              );
              int etaMinutes = ((distanceInMeters / 1000) / 40 * 60).round();
              updatedEtas[busId] = etaMinutes <= 1
                  ? 'وصل تقريباً 🏁'
                  : '$etaMinutes دقيقة';
            }
          }
          if (mounted) setState(() => _busEtas = updatedEtas);
        });
  }

  void _refreshTrips() {
    setState(() {
      _tripsFuture = _fetchTodayTripsData();
    });
  }

  void _showNotification(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _processBooking(
    String tripId,
    String busId,
    String boardingType,
    String? stationName,
    double? lat,
    double? lng,
  ) async {
    _showNotification('جاري تأكيد الحجز...', true);

    final status = await _dbService.bookSeat(
      tripId,
      busId,
      boardingType: boardingType,
      stationName: stationName,
      lat: lat,
      lng: lng,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (status == 'success') {
      _showNotification('تم حجز مقعدك بنجاح! 🚌', true);
      _refreshTrips();
    } else if (status == 'already_booked') {
      _showNotification(
        'لقد قمت بحجز مقعد مسبقاً! لا يمكنك الحجز أكثر من مرة.',
        false,
      );
    } else if (status == 'full') {
      _showNotification('عذراً، الرحلة ممتلئة بالكامل.', false);
    } else {
      _showNotification('حدث خطأ أثناء الحجز.', false);
    }
  }

  void _showBookingOptionsDialog(String tripId, String busId) {
    String selectedType = 'المجمع';
    Map<String, dynamic>? selectedStation;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.where_to_vote,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'تحديد مكان الركوب',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'من أين تود الركوب في هذه الرحلة؟',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedType == 'المجمع'
                                ? const Color(0xFF246BFD)
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: selectedType == 'المجمع'
                              ? Colors.blue.shade50
                              : Colors.white,
                        ),
                        child: RadioListTile<String>(
                          title: const Text(
                            'من مجمع الانطلاق',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: 'المجمع',
                          groupValue: selectedType,
                          activeColor: const Color(0xFF246BFD),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedType = val!;
                              selectedStation = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedType == 'محطة طريق'
                                ? const Color(0xFF246BFD)
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: selectedType == 'محطة طريق'
                              ? Colors.blue.shade50
                              : Colors.white,
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text(
                                'محطة على الطريق',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              value: 'محطة طريق',
                              groupValue: selectedType,
                              activeColor: const Color(0xFF246BFD),
                              onChanged: (val) {
                                setDialogState(() => selectedType = val!);
                              },
                            ),
                            if (selectedType == 'محطة طريق')
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 20,
                                  left: 20,
                                  bottom: 15,
                                ),
                                child:
                                    DropdownButtonFormField<
                                      Map<String, dynamic>
                                    >(
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'اختر المحطة',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 0,
                                            ),
                                      ),
                                      value: selectedStation,
                                      items: _stationsList.map((station) {
                                        return DropdownMenuItem<
                                          Map<String, dynamic>
                                        >(
                                          value: station,
                                          child: Text(
                                            station['name'],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setDialogState(
                                        () => selectedStation = val,
                                      ),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedType == 'محطة طريق' &&
                          selectedStation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء اختيار المحطة أولاً!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop();
                      _processBooking(
                        tripId,
                        busId,
                        selectedType,
                        selectedStation?['name'],
                        selectedStation?['latitude'],
                        selectedStation?['longitude'],
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF246BFD),
                    ),
                    child: const Text(
                      'تأكيد الحجز',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🌟 دالة الإلغاء يجب تعديلها بملف my_reservations_view لتنقص من جدول trips
  void _showCancelInstruction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'لإلغاء الحجز، يرجى التوجه لعلامة تبويب (رحلتي).',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'الرحلات المتاحة',
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات.'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(child: Text('لا توجد رحلات مجدولة لليوم.'));

          final trips = snapshot.data!;

          if (_bookedTripId != null) {
            trips.sort((a, b) {
              if (a['trip_id'].toString() == _bookedTripId) return -1;
              if (b['trip_id'].toString() == _bookedTripId) return 1;
              return 0;
            });
          }

          // 🌟 تم إضافة التنويه في الأعلى وتغليف الـ ListView بـ Expanded و Column
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // 🌟 الشريط التنبيهي
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ملاحظة: هذه الرحلات ثابتة وتتكرر يومياً في نفس الأوقات من الأحد إلى الخميس.',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 🌟 قائمة الرحلات
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      return _buildTripCard(trips[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final String tripId = trip['trip_id'];
    final String busId = trip['bus_id'];
    final String busNumber = trip['bus_number'];
    final String routeName = trip['route_name'];
    final String driverName = trip['driver_name'];
    final String departureTime = trip['departure_time'];
    final int maxCapacity = trip['capacity'];
    final int currentPassengers = trip['current_passengers'];
    final int availableSeats = maxCapacity - currentPassengers;
    final bool isFull = availableSeats <= 0;

    bool isBookedByMe = (tripId == _bookedTripId);
    bool hasBookedAnyTrip = (_bookedTripId != null);

    Color buttonColor;
    String buttonText;

    if (isBookedByMe) {
      buttonColor = Colors.green;
      buttonText = 'تم الحجز ✔️';
    } else if (isFull) {
      buttonColor = Colors.grey;
      buttonText = 'ممتلئ';
    } else if (hasBookedAnyTrip) {
      buttonColor = Colors.grey.shade400;
      buttonText = 'احجز الآن';
    } else {
      buttonColor = const Color(0xFF246BFD);
      buttonText = 'احجز الآن';
    }

    bool isButtonDisabled = isFull || hasBookedAnyTrip;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alt_route,
                    color: Color(0xFF246BFD),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_bus,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'باص: $busNumber',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'السائق: $driverName',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'الانطلاق: $departureTime',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event_seat,
                            size: 16,
                            color: isFull ? Colors.red : Colors.blueGrey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isFull ? 'ممتلئ' : '$availableSeats مقاعد متاحة',
                            style: TextStyle(
                              color: isFull ? Colors.red : Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'الوصول التقريبي إليك: ${_busEtas[busId] ?? 'جاري الحساب...'}',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: (isButtonDisabled && !isBookedByMe)
                      ? null
                      : () {
                          if (isBookedByMe) {
                            _showCancelInstruction(); // 🌟 يتم الإلغاء من واجهة تذكرتي لضمان الأمان
                          } else {
                            _showBookingOptionsDialog(tripId, busId);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    disabledBackgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
