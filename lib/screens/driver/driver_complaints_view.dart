import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverComplaintsView extends StatefulWidget {
  const DriverComplaintsView({Key? key}) : super(key: key);

  @override
  State<DriverComplaintsView> createState() => _DriverComplaintsViewState();
}

class _DriverComplaintsViewState extends State<DriverComplaintsView> {
  final TextEditingController _descriptionController = TextEditingController();

  // أنواع البلاغات المتاحة للسائق
  final List<String> _complaintTypes = [
    'عطل فني في الباص',
    'أزمة سير خانقة / تأخير',
    'حادث مروري',
    'أخرى',
  ];
  final TextEditingController _detailsController = TextEditingController();

  String? _selectedType;
  bool _isLoading = false;

  Future<void> _submitComplaint() async {
    // تأكد من تغيير أسماء المتغيرات (مثل _detailsController و _selectedType) لتطابق الأسماء الموجودة في كودك
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة التفاصيل أولاً')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // 🌟 دمج نوع البلاغ مع التفاصيل في رسالة واحدة لكي نقبلها في عمود message
      String finalMessage =
          "نوع البلاغ: $_selectedType\nالتفاصيل: ${_detailsController.text.trim()}";

      await Supabase.instance.client.from('complaints').insert({
        'user_id': userId,
        'message': finalMessage,
        'created_at': DateTime.now()
            .toIso8601String(), // استخدام الاسم الصحيح للوقت
        'status': 'pending',
        'bus_number': 'غير محدد', // لتفادي خطأ الـ Null الذي أصلحناه سابقاً
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال البلاغ بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      _detailsController.clear();
    } on PostgrestException catch (e) {
      // 🌟 طباعة الخطأ الحقيقي من قاعدة البيانات لكي نعرفه فوراً
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في قاعدة البيانات: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'الإبلاغ عن مشكلة',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نوع البلاغ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF246BFD),
              ),
            ),
            const SizedBox(height: 10),
            // قائمة منسدلة لاختيار نوع المشكلة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('اختر نوع المشكلة...'),
                  value: _selectedType,
                  items: _complaintTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              'تفاصيل المشكلة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF246BFD),
              ),
            ),
            const SizedBox(height: 10),
            // حقل النص التفصيلي
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'اكتب تفاصيل المشكلة هنا لمساعدتنا في حلها بسرعة...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF246BFD)),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // زر الإرسال
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF246BFD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'إرسال البلاغ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
