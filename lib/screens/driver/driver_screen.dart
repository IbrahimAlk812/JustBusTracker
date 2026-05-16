import 'package:flutter/material.dart';
// استدعاء ملف البطاقة اللي انت عملته
import 'package:just_bus_tracker/screens/driver/bus_info_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  
  void startTrip() {
    print("Trip started");
  }

  void endTrip() {
    print("Trip ended");
  }

  
void _showEmergencyDialog(BuildContext context) {
    // متغيرات لحفظ اختيار وكتابة السائق
    String selectedIssue = 'عطل ميكانيكي'; // الخيار الافتراضي
    TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('الإبلاغ عن طارئ 🚨', style: TextStyle(color: Colors.red)),
          content: StatefulBuilder( // نستخدمها عشان نحدث الـ Dropdown جوا الـ Dialog
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. قائمة منسدلة للخيارات السريعة (عشان السائق ما يطبع كثير)
                  DropdownButtonFormField<String>(
                    value: selectedIssue,
                    decoration: const InputDecoration(labelText: 'نوع المشكلة المبدئي'),
                    items: ['عطل ميكانيكي', 'حادث سير', 'أزمة مرورية خانقة', 'أخرى']
                        .map((issue) => DropdownMenuItem(value: issue, child: Text(issue)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedIssue = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // 2. مربع نص للتفاصيل (اختياري)
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'تفاصيل إضافية (اختياري)',
                      hintText: 'مثال: البنجر في العجل اليمين...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // إغلاق النافذة
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // إغلاق النافذة أولاً
                Navigator.pop(context);

                // دمج الخيار الجاهز مع التفاصيل اللي كتبها السائق (إن وجدت)
                String finalIssue = selectedIssue;
                if (detailsController.text.trim().isNotEmpty) {
                  finalIssue += ' - ${detailsController.text.trim()}';
                }

                // إرسال البلاغ للداتا بيز
                try {
                  await Supabase.instance.client.from('complaints').insert({
                    'bus_number': 'B-101', 
                    'issue_type': finalIssue, // نرسل النص المدمج هنا
                    'status': 'معلقة',
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال البلاغ بنجاح ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('إرسال البلاغ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final String assignedBus = 'B-101'; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // استدعاء البطاقة من الملف الثاني
              // 👇 بطاقة معلومات الباص الديناميكية 👇
            FutureBuilder<List<Map<String, dynamic>>>(
              // نستعلم عن الباص الذي يقوده السائق حالياً من جدول الباصات
              future: Supabase.instance.client
                  .from('buses')
                  .select()
                  .eq('bus_number', assignedBus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                String routeName = 'غير محدد';
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // جلب اسم المسار الحقيقي من الداتا بيز
                  routeName = snapshot.data![0]['route'] ?? 'غير محدد';
                }

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50], // لون أزرق فاتح متناسق
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue[200]!),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Bus: $assignedBus',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Route: $routeName',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            // 👆 نهاية البطاقة الديناميكية 👆

              // 1. تعريف رقم الباص (حالياً سنضعه كمتغير، لاحقاً سيسحب من بيانات الدخول)

// 2. ويدجت العداد اللحظي
// 👇 ويدجت العداد اللحظي
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('reservations')
                    .stream(primaryKey: ['id']),
                builder: (context, snapshot) {
                  // الفلترة الذكية (نأخذ باصنا الحالي والحجز النشط فقط)
                  final allReservations = snapshot.data ?? [];
                  final activeReservations = allReservations.where((res) => 
                      res['bus_number'] == assignedBus && res['status'] == 'نشط'
                  ).toList();

                  int passengersCount = activeReservations.length;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'عدد الركاب المحجوزين حالياً',
                          style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_alt, size: 40, color: Colors.blue),
                            const SizedBox(width: 15),
                            Text(
                              '$passengersCount',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'من أصل 50 مقعد', 
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 50),

              
              // زر بدء الرحلة
              ElevatedButton(
                onPressed: startTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Start Trip', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
              const SizedBox(height: 25),
              
              // زر إنهاء الرحلة
              ElevatedButton(
                onPressed: endTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('End Trip', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
              const SizedBox(height: 60), 
              
              // زر الطوارئ
              ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  ),
  icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
  label: const Text(
    'Report Emergency',
    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
  ),
  onPressed: () {
    // استدعاء النافذة المنبثقة
    _showEmergencyDialog(context);
  },
)
            ],
          ),
        ),
      ),
    );
  }
}