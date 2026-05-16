import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintsView extends StatelessWidget {
  const ComplaintsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🔥 السحر هنا: دالة stream تقوم بجلب البيانات وتحديثها لحظياً!
    // طلبنا منها جلب الشكاوى "المعلقة" فقط، وترتيبها من الأحدث للأقدم
    final complaintsStream = Supabase.instance.client
        .from('complaints')
        .stream(primaryKey: ['id'])
        .eq('status', 'معلقة') 
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بلاغات الطوارئ 🚨'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: complaintsStream,
        builder: (context, snapshot) {
          // حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // حالة الخطأ
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final complaints = snapshot.data ?? [];

          // حالة عدم وجود شكاوى (الوضع آمن)
          if (complaints.isEmpty) {
            return const Center(
              child: Text(
                'الوضع آمن، لا توجد بلاغات حالياً ✅',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            );
          }

          // عرض الشكاوى الحقيقية
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              
              // ترتيب وقت الشكوى
              final date = DateTime.parse(complaint['created_at']).toLocal();
              final timeString = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

              return Card(
                color: Colors.red[50], // خلفية حمراء خفيفة
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.red, width: 2), // إطار أحمر عريض
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                  title: Text(
                    'باص رقم: ${complaint['bus_number']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    'السبب: ${complaint['issue_type']}\nوقت البلاغ: $timeString',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      // عند الضغط على "تم الحل"، نحدث الداتا بيز
                      // وبفضل الـ Stream، ستختفي البطاقة فوراً من الشاشة!
                      await Supabase.instance.client
                          .from('complaints')
                          .update({'status': 'تم الحل'})
                          .eq('id', complaint['id']);
                    },
                    child: const Text('تم الحل', style: TextStyle(color: Colors.white)),
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