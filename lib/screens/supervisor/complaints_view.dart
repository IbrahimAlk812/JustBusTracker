import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintsView extends StatelessWidget {
  const ComplaintsView({super.key});

  // 🌟 نافذة منبثقة لكتابة نص توضيحي اختياري للحل
  void _showResolveDialog(BuildContext context, String complaintId) {
    final TextEditingController responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'تأكيد حل المشكلة',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يمكنك كتابة نص توضيحي للطالب حول كيفية حل المشكلة أو الإجراء المتخذ (اختياري):',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: responseController,
              maxLines: 3,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'مثال: تم التواصل مع السائق / عطل تقني وتم إصلاحه...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final String responseText = responseController.text.trim();
              Navigator.pop(context); // إغلاق النافذة
              _markAsResolved(context, complaintId, responseText); // تنفيذ الحل
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'تأكيد وإرسال',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 دالة تحديث حالة الشكوى مع حفظ الرد الاختياري
  Future<void> _markAsResolved(
    BuildContext context,
    String complaintId,
    String responseText,
  ) async {
    try {
      await Supabase.instance.client
          .from('complaints')
          .update({
            'status': 'resolved',
            'admin_response': responseText.isEmpty
                ? null
                : responseText, // حفظ الرد إذا وُجد
          })
          .eq('id', complaintId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إغلاق البلاغ بنجاح وتنبيه المستخدم! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تحديث الحالة.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'صندوق الشكاوى والبلاغات',
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('complaints')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('صندوق الشكاوى فارغ حالياً.'));
          }

          // 🔄 منطق الفرز الذكي: تحويل البيانات لقائمة وفرزها لكي تنزل الشكاوى المحلولة للأسفل
          final complaints = List<Map<String, dynamic>>.from(snapshot.data!);
          complaints.sort((a, b) {
            final String statusA = a['status'] ?? 'pending';
            final String statusB = b['status'] ?? 'pending';
            if (statusA == 'resolved' && statusB == 'pending')
              return 1; // المحلولة تنزل تحت
            if (statusA == 'pending' && statusB == 'resolved')
              return -1; // المنتظرة تطلع فوق
            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final item = complaints[index];
              final String complaintId = item['id'].toString();
              final String complaintText = item['message'] ?? 'لا يوجد نص';
              final String rawTime = item['created_at'] ?? '';
              final String userId = item['user_id'] ?? '';
              final String status = item['status'] ?? 'pending';
              final String? adminResponse = item['admin_response'];

              bool isResolved = status == 'resolved';
              String formattedTime = rawTime.length > 16
                  ? rawTime.substring(0, 16).replaceAll('T', ' ')
                  : rawTime;

              return FutureBuilder<Map<String, dynamic>>(
                future: Supabase.instance.client
                    .from('profiles')
                    .select()
                    .eq('id', userId)
                    .single(),
                builder: (context, profileSnapshot) {
                  String senderName = 'جاري التحميل...';
                  String senderRole = 'student';

                  if (profileSnapshot.hasData) {
                    senderName =
                        profileSnapshot.data!['name'] ?? 'مستخدم مجهول';
                    senderRole = profileSnapshot.data!['role'] ?? 'student';
                  }

                  bool isStudent = (senderRole == 'student');

                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isResolved ? 0 : 2,
                      color: isResolved ? Colors.grey.shade100 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isResolved
                              ? Colors.green.shade300
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isStudent
                                          ? Colors.blue.shade50
                                          : Colors.orange.shade50,
                                      child: Icon(
                                        isStudent
                                            ? Icons.school
                                            : Icons.drive_eta,
                                        color: isStudent
                                            ? Colors.blue.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          formattedTime,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isStudent
                                        ? Colors.blue.shade600
                                        : Colors.orange.shade600,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isStudent ? 'طالب' : 'سائق',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              complaintText,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isResolved
                                    ? Colors.grey.shade700
                                    : Colors.black87,
                              ),
                            ),

                            // إظهار رد المشرف إذا كانت الشكوى محلولة ويوجد رد
                            if (isResolved && adminResponse != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'إجراء الحل: $adminResponse',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 15),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: isResolved
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'تم حل المشكلة',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: () => _showResolveDialog(
                                        context,
                                        complaintId,
                                      ), // 🌟 فتح النافذة المنبثقة للحل
                                      icon: const Icon(
                                        Icons.done_all,
                                        size: 18,
                                      ),
                                      label: const Text('تحديد كمحلولة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
