import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusInfoCard extends StatefulWidget {
  const BusInfoCard({Key? key}) : super(key: key);

  @override
  State<BusInfoCard> createState() => _BusInfoCardState();
}

class _BusInfoCardState extends State<BusInfoCard> {
  // معرف الباص الافتراضي (يمكنك استبداله لاحقاً بناءً على معرف السائق بعد الـ Login)
  final String targetBusId = 'ed273233-26b1-4951-b850-15c4c5d80cff'; 

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // 1️⃣ الاستماع للحظي لجدول الباصات (Buses) في Supabase
      stream: Supabase.instance.client
          .from('buses')
          .stream(primaryKey: ['id'])
          .eq('id', targetBusId), // فلترة البيانات للباص الحالي فقط
      builder: (context, snapshot) {
        // 2️⃣ حالة الانتظار لحين تحميل البيانات من السيرفر لأول مرة
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // 3️⃣ التعامل مع الأخطاء في حال فشل الاتصال بقاعدة البيانات
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            color: Colors.red.shade50,
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'خطأ في جلب بيانات الباص',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // 4️⃣ استخراج البيانات الحية المستلمة من Supabase
        final busData = snapshot.data!.first;
        final String busNumber = busData['bus_number'] ?? 'N/A';
        final String routeName = busData['route'] ?? 'لم يحدد مسار';
        
        // جلب عدد الحجوزات الحالي والسعة القصوى من الأعمدة في الداتا بيز
        final int currentPassengers = busData['current_passengers'] ?? 0;
        final int maxCapacity = busData['capacity'] ?? 50;

        // 5️⃣ تصميم الواجهة وعرض البيانات والعداد اللحظي
        return Card(
          elevation: 5,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blue.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
            child: Column(
              children: [
                Text(
                  'Bus: $busNumber',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Route: $routeName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 30, thickness: 1, color: Colors.blue),
                
                // ⚡ عداد الركاب اللحظي المطلوب في المهمة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_alt_rounded, color: Colors.green, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'الركاب الحاليين: $currentPassengers / $maxCapacity',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}