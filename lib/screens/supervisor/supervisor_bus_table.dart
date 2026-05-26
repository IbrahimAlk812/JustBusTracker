import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupervisorBusTable extends StatefulWidget {
  const SupervisorBusTable({super.key});

  @override
  State<SupervisorBusTable> createState() => _SupervisorBusTableState();
}

class _SupervisorBusTableState extends State<SupervisorBusTable> {
  // 🌟 دالة فتح نافذة الإضافة أو التعديل
  Future<void> _showAddEditBusDialog({Map<String, dynamic>? bus}) async {
    final isEditing = bus != null;
    final formKey = GlobalKey<FormState>();

    // تعبئة الحقول إذا كنا في وضع التعديل
    final busNumberController = TextEditingController(
      text: bus?['bus_number']?.toString() ?? '',
    );
    final routeController = TextEditingController(
      text: bus?['route']?.toString() ?? '',
    );
    final capacityController = TextEditingController(
      text: bus?['capacity']?.toString() ?? '',
    );

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
                      labelText: 'رقم/رمز الباص',
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
                    controller: routeController,
                    decoration: InputDecoration(
                      labelText: 'مسار الباص (نقطة البداية - النهاية)',
                      prefixIcon: const Icon(Icons.route),
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
                      labelText: 'السعة القصوى (عدد المقاعد)',
                      prefixIcon: const Icon(Icons.event_seat),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'هذا الحقل مطلوب';
                      if (int.tryParse(val) == null)
                        return 'الرجاء إدخال رقم صحيح';
                      return null;
                    },
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
                  Navigator.pop(context); // إغلاق النافذة
                  await _saveBus(
                    id: bus?['id'],
                    busNumber: busNumberController.text,
                    route: routeController.text,
                    capacity: int.parse(capacityController.text),
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

  // 🌟 دالة الحفظ في قاعدة البيانات (Supabase)
  Future<void> _saveBus({
    dynamic id,
    required String busNumber,
    required String route,
    required int capacity,
  }) async {
    try {
      if (id == null) {
        // إضافة باص جديد (Insert)
        await Supabase.instance.client.from('buses').insert({
          'bus_number': busNumber,
          'route': route,
          'capacity': capacity,
          'current_passengers': 0, // يبدأ الباص فارغاً
        });
        _showNotification('تمت إضافة الباص بنجاح ✅', true);
      } else {
        // تعديل باص موجود (Update)
        await Supabase.instance.client
            .from('buses')
            .update({
              'bus_number': busNumber,
              'route': route,
              'capacity': capacity,
            })
            .eq('id', id);
        _showNotification('تم تحديث بيانات الباص بنجاح 🔄', true);
      }
    } catch (e) {
      debugPrint('Error saving bus: $e');
      _showNotification('حدث خطأ أثناء حفظ البيانات', false);
    }
  }

  // دالة مساعدة لإظهار الإشعارات
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
          'إدارة أسطول الباصات',
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

      // 🌟 زر الإضافة العائم
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddEditBusDialog(), // فتح النافذة بدون إرسال بيانات (وضع الإضافة)
        backgroundColor: const Color(0xFF246BFD),
        icon: const Icon(Icons.directions_bus, color: Colors.white),
        label: const Text(
          'إضافة باص',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      // 🌟 جدول الباصات الحي
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('buses')
            .stream(primaryKey: ['id'])
            .order('id', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد باصات مسجلة في النظام حالياً.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final buses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 80,
            ), // ترك مساحة للزر العائم
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
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // أيقونة الباص الدائرية
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

                        // تفاصيل الباص
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
                              Text(
                                'المسار: ${bus['route'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'الركاب: $currentPassengers / $capacity',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: currentPassengers >= capacity
                                          ? Colors.red
                                          : Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 🌟 زر التعديل
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note,
                            color: Colors.orange,
                            size: 32,
                          ),
                          tooltip: 'تعديل بيانات الباص',
                          onPressed: () => _showAddEditBusDialog(
                            bus: bus,
                          ), // فتح النافذة مع إرسال بيانات الباص (وضع التعديل)
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
