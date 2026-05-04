import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// تأكد من صحة مسارات الاستيراد لشاشاتك
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // للتحكم في الحقول
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // الدالة المسؤولة عن تسجيل الدخول والتوجيه
  Future<void> _loginAndRoute() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. تسجيل الدخول عبر Supabase Auth
      final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = res.user;

      if (user != null) {
        // 2. جلب نوع المستخدم (role) من جدول profiles
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id) // مطابقة الـ id مع حساب الـ Auth
            .single();

        final String userRole = profileData['role'];

        if (!mounted) return; // للتأكد من أن الشاشة لا زالت فعالة

        // 3. التوجيه (Routing) بناءً على الـ Role
        if (userRole == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
          );
        } else if (userRole == 'supervisor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SupervisorDashboard()),
          );
        } else {
          // يمكن إضافة شرط للسائق لاحقاً
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم التعرف على صلاحيات الحساب.')),
          );
        }
      }
    } on AuthException catch (e) {
      // معالجة أخطاء الدخول (إيميل أو باسوورد خطأ)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تسجيل الدخول: ${e.message}')),
      );
    } catch (e) {
      // أضف هذا السطر لطباعة الخطأ في شاشة الـ Debug Console في VS Code
      print('🔥 الخطأ الحقيقي هو: $e'); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.')),
      );
    
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // حقل الإيميل
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // حقل الباسوورد
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            // زر تسجيل الدخول
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _loginAndRoute,
                    child: const Text('تسجيل الدخول'),
                  ),
          ],
        ),
      ),
    );
  }
}