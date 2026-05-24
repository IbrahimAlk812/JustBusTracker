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
    'أخرى'
  ];
  String? _selectedType;
  bool _isLoading = false;

  // 🚀 دالة إرسال الشكوى إلى قاعدة البيانات
  Future<void> _submitComplaint() async {
    if (_selectedType == null || _descriptionController.text.trim().isEmpty) {
      _showSnackBar('الرجاء اختيار نوع البلاغ وكتابة التفاصيل', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // الحصول على الـ ID الخاص بالسائق الحالي
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // إرسال البيانات لجدول complaints
      await Supabase.instance.client.from('complaints').insert({
        'user_id': userId, // ربط الشكوى بالسائق
        'type': _selectedType, // نوع العطل
        'description': _descriptionController.text.trim(), // التفاصيل
        'status': 'Pending', // حالة الطلب مبدئياً
        // 'bus_id': '...', // يمكنك إرسال رقم الباص أيضاً إذا كان محفوظاً
      });

      _showSnackBar('تم إرسال البلاغ بنجاح إلى المشرف');
      
      // تفريغ الحقول بعد الإرسال
      setState(() {
        _selectedType = null;
        _descriptionController.clear();
      });
      
    } catch (e) {
      debugPrint('خطأ في إرسال البلاغ: $e');
      _showSnackBar('حدث خطأ أثناء الإرسال، حاول مرة أخرى', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text('الإبلاغ عن مشكلة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 10),
            // حقل النص التفصيلي
            TextField(
              controller: _descriptionController,
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
                  borderSide: const BorderSide(color: Color(0xFF1A237E)),
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
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'إرسال البلاغ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}