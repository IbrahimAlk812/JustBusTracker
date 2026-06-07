import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. الشاشة الرئيسية (البوابة)
// ==========================================
class SupervisorBusTable extends StatelessWidget {
  const SupervisorBusTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'إدارة البيانات والرحلات',
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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMenuCard(
                context,
                title: 'إدارة وتعديل الباصات',
                subtitle: 'إضافة باصات جديدة، تعيين السائقين، وتعديل السعة',
                icon: Icons.directions_bus,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageBusesScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuCard(
                context,
                title: 'إدارة الرحلات الثابتة (اليومية)', // 🌟 تعديل الاسم
                subtitle: 'جدولة مواعيد الانطلاق الثابتة وربطها بالباصات',
                icon: Icons.alt_route,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageTripsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. شاشة إدارة الباصات (بدون تغيير)
// ==========================================
class ManageBusesScreen extends StatefulWidget {
  const ManageBusesScreen({super.key});
  @override
  State<ManageBusesScreen> createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  List<Map<String, dynamic>> _driversList = [];

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id, name')
          .eq('role', 'driver');
      if (mounted)
        setState(() => _driversList = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
    }
  }

  String _getDriverName(String? driverId) {
    if (driverId == null) return 'غير معيّن';
    final driver = _driversList.firstWhere(
      (d) => d['id'].toString() == driverId,
      orElse: () => {'name': 'غير معيّن'},
    );
    return driver['name'].toString();
  }

  Future<void> _showAddEditBusDialog({Map<String, dynamic>? bus}) async {
    final isEditing = bus != null;
    final formKey = GlobalKey<FormState>();
    final busNumberController = TextEditingController(
      text: bus?['bus_number']?.toString() ?? '',
    );
    final capacityController = TextEditingController(
      text: bus?['capacity']?.toString() ?? '',
    );
    String? selectedDriverId = bus?['driver_id']?.toString();

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.add_circle,
                color: const Color(0xFF246BFD),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'تعديل بيانات الباص' : 'إضافة باص جديد',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: busNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم الباص',
                      prefixIcon: const Icon(Icons.directions_bus),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'السعة القصوى',
                      prefixIcon: const Icon(Icons.event_seat),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'مطلوب';
                      if (int.tryParse(val) == null) return 'رقم غير صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: InputDecoration(
                      labelText: 'تعيين سائق الباص',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: _driversList
                        .map(
                          (driver) => DropdownMenuItem<String>(
                            value: driver['id'].toString(),
                            child: Text(driver['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => selectedDriverId = val,
                    validator: (val) =>
                        val == null ? 'الرجاء اختيار سائق' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF246BFD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _saveBus(
                    id: bus?['id'],
                    busNumber: busNumberController.text,
                    capacity: int.parse(capacityController.text),
                    driverId: selectedDriverId!,
                  );
                }
              },
              child: Text(
                isEditing ? 'حفظ التعديلات' : 'إضافة للباصات',
                style: const TextStyle(
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

  Future<void> _saveBus({
    dynamic id,
    required String busNumber,
    required int capacity,
    required String driverId,
  }) async {
    try {
      if (id == null) {
        await Supabase.instance.client.from('buses').insert({
          'bus_number': busNumber,
          'capacity': capacity,
          'current_passengers': 0,
          'driver_id': driverId,
        });
        _showNotification('تمت إضافة الباص بنجاح ✅', true);
      } else {
        await Supabase.instance.client
            .from('buses')
            .update({
              'bus_number': busNumber,
              'capacity': capacity,
              'driver_id': driverId,
            })
            .eq('id', id);
        _showNotification('تم تحديث بيانات الباص بنجاح 🔄', true);
      }
    } catch (e) {
      _showNotification('حدث خطأ أثناء حفظ البيانات', false);
    }
  }

  void _showNotification(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
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
          'إدارة الباصات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF246BFD),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBusDialog(),
        backgroundColor: const Color(0xFF246BFD),
        icon: const Icon(Icons.directions_bus, color: Colors.white),
        label: const Text(
          'إضافة باص',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('buses')
            .stream(primaryKey: ['id'])
            .order('bus_number', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(
              child: Text(
                'لا توجد باصات مسجلة.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );

          final buses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              final int capacity =
                  int.tryParse(bus['capacity']?.toString() ?? '0') ?? 0;
              final int currentPassengers =
                  int.tryParse(bus['current_passengers']?.toString() ?? '0') ??
                  0;

              return Directionality(
                textDirection: TextDirection.rtl,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Color(0xFF246BFD),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'باص رقم: ${bus['bus_number'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF246BFD),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'السائق: ${_getDriverName(bus['driver_id']?.toString())}',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note,
                            color: Colors.orange,
                            size: 32,
                          ),
                          onPressed: () => _showAddEditBusDialog(bus: bus),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. شاشة إدارة الرحلات (النظام الثابت المحدث)
// ==========================================
class ManageTripsScreen extends StatefulWidget {
  const ManageTripsScreen({super.key});

  @override
  State<ManageTripsScreen> createState() => _ManageTripsScreenState();
}

class _ManageTripsScreenState extends State<ManageTripsScreen> {
  List<Map<String, dynamic>> _busesList = [];
  List<Map<String, dynamic>> _driversList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final driversData = await Supabase.instance.client
          .from('profiles')
          .select('id, name')
          .eq('role', 'driver');
      final busesData = await Supabase.instance.client
          .from('buses')
          .select('id, bus_number, driver_id');
      if (mounted) {
        setState(() {
          _driversList = List<Map<String, dynamic>>.from(driversData);
          _busesList = List<Map<String, dynamic>>.from(busesData);
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  String _getBusWithDriverName(String busId) {
    final bus = _busesList.firstWhere(
      (b) => b['id'].toString() == busId,
      orElse: () => {'bus_number': '؟', 'driver_id': null},
    );
    final driverId = bus['driver_id']?.toString();
    String driverName = 'غير معيّن';
    if (driverId != null) {
      final driver = _driversList.firstWhere(
        (d) => d['id'].toString() == driverId,
        orElse: () => {'name': 'غير معيّن'},
      );
      driverName = driver['name'].toString();
    }
    return 'باص رقم ${bus['bus_number']} (السائق: $driverName)';
  }

  Future<void> _showAddEditTripDialog({Map<String, dynamic>? trip}) async {
    final isEditing = trip != null;
    final formKey = GlobalKey<FormState>();
    final routeController = TextEditingController(
      text: trip?['route_name']?.toString() ?? '',
    );
    final timeController = TextEditingController(
      text: trip?['departure_time']?.toString() ?? '',
    );
    String? selectedBusId = trip?['bus_id']?.toString();

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit : Icons.add_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'تعديل الرحلة' : 'برمجة رحلة يومية جديدة',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedBusId,
                    decoration: InputDecoration(
                      labelText: 'اختر الباص والسائق',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: _busesList
                        .map(
                          (bus) => DropdownMenuItem<String>(
                            value: bus['id'].toString(),
                            child: Text(
                              _getBusWithDriverName(bus['id'].toString()),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => selectedBusId = val,
                    validator: (val) =>
                        val == null ? 'الرجاء اختيار الباص' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: routeController,
                    decoration: InputDecoration(
                      labelText: 'المسار (مثال: إربد - التكنو)',
                      prefixIcon: const Icon(Icons.route),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 15),
                  // 🌟 تم إزالة حقل التاريخ تماماً
                  TextFormField(
                    controller: timeController,
                    decoration: InputDecoration(
                      labelText: 'وقت الانطلاق (مثال: 08:00 AM)',
                      prefixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'مطلوب' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  // 🌟 استدعاء الحفظ بدون تاريخ
                  await _saveTrip(
                    id: trip?['id'],
                    busId: selectedBusId!,
                    routeName: routeController.text,
                    departureTime: timeController.text,
                  );
                }
              },
              child: Text(
                isEditing ? 'حفظ التعديلات' : 'إضافة الرحلة',
                style: const TextStyle(
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

  // 🌟 دالة الحفظ أصبحت بدون trip_date
  Future<void> _saveTrip({
    dynamic id,
    required String busId,
    required String routeName,
    required String departureTime,
  }) async {
    try {
      if (id == null) {
        await Supabase.instance.client.from('trips').insert({
          'bus_id': busId,
          'route_name': routeName,
          'departure_time': departureTime,
          'status': 'مجدولة',
        });
        _showNotification('تمت برمجة الرحلة اليومية بنجاح ✅', true);
      } else {
        await Supabase.instance.client
            .from('trips')
            .update({
              'bus_id': busId,
              'route_name': routeName,
              'departure_time': departureTime,
            })
            .eq('id', id);
        _showNotification('تم تحديث بيانات الرحلة بنجاح 🔄', true);
      }
    } catch (e) {
      _showNotification('حدث خطأ أثناء حفظ البيانات', false);
    }
  }

  void _showNotification(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
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
          'إدارة الرحلات (اليومية)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTripDialog(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'رحلة يومية جديدة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // 🌟 الترتيب أصبح يعتمد على الوقت فقط بدلاً من التاريخ
        stream: Supabase.instance.client
            .from('trips')
            .stream(primaryKey: ['id'])
            .order('departure_time', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(
              child: Text(
                'لا توجد رحلات مبرمجة.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );

          final trips = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.alt_route,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trip['route_name']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _getBusWithDriverName(
                                  trip['bus_id'].toString(),
                                ),
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'تتكرر يومياً في تمام الساعة: ${trip['departure_time']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note,
                            color: Colors.orange,
                            size: 32,
                          ),
                          onPressed: () => _showAddEditTripDialog(trip: trip),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
