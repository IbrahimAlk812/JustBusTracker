import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // 🌟 استدعاء خطوط جوجل للخط الجديد
import 'package:just_bus_tracker/screens/auth/signup_screen.dart';
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';
import 'package:just_bus_tracker/screens/driver/driver_home_screen.dart';

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

  // الدالة المسؤولة عن تسجيل الدخول والتوجيه (تم الحفاظ عليها كاملة 100%)
  Future<void> _loginAndRoute() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. تسجيل الدخول عبر Supabase Auth
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final User? user = res.user;

      if (user != null) {
        // 2. جلب نوع المستخدم (role) وحالة التفعيل من جدول profiles
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('role, is_approved')
            .eq('id', user.id)
            .single();

        final String userRole = profileData['role'];
        final bool isApproved = profileData['is_approved'] ?? false;

        if (!mounted) return;

        // 🌟 الجدار الأمني: إذا كان الحساب غير مفعل، نمنع الدخول
        if (!isApproved) {
          await Supabase.instance.client.auth.signOut(); // تسجيل خروج فوري
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('عذراً، حسابك قيد المراجعة بانتظار موافقة المشرف.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        // 3. التوجيه (Routing) بناءً على الـ Role المحدث
        if (userRole == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
          );
        } else if (userRole == 'supervisor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SupervisorDashboard(),
            ),
          );
        } else if (userRole == 'driver') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم التعرف على صلاحيات الحساب.')),
          );
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تسجيل الدخول: ${e.message}')),
      );
    } catch (e) {
      print('🔥 الخطأ الحقيقي هو: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.'),
        ),
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
    // اللون الأزرق الحيوي الجديد لتنسيقات شعار الشاشة المعتمَد
    const Color primaryBlue = Color(0xFF246BFD);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // خلفية ناعمة ومريحة
      body: Center(
        // 🌟 لضمان عدم حدوث خطأ Overflow عند خروج لوحة المفاتيح أثناء الكتابة
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🌟 1. شعار التطبيق الدائري العصري الجديد
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(
                    alpha: 0.1,
                  ), // خلفية زرقاء شفافة
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus_rounded, // أيقونة حافلة أنيقة ومتناسقة
                  size: 75,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),

              // 🌟 2. اسم التطبيق الرئيسي
              Text(
                'Just Bus Tracker',
                style: GoogleFonts.almarai(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // 🌟 3. الشعار اللفظي أو الوصف الفرعي باللغة العربية
              Text(
                'نظام تتبع باصات التكنو الذكي',
                style: GoogleFonts.almarai(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 45), // مسافة تفصل الهوية عن حقول الإدخال
              // حقل الإيميل الجامعي
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني الجامعي',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // حقل كلمة المرور
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
              ),
              const SizedBox(height: 35),

              // زر تسجيل الدخول التفاعلي
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      )
                    : ElevatedButton(
                        onPressed: _loginAndRoute,
                        child: const Text('تسجيل الدخول'),
                      ),
              ),

              const SizedBox(height: 25),

              // زر الانتقال لإنشاء حساب جديد
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: Text(
                  'ليس لديك حساب؟ أنشئ حساباً جديداً',
                  style: GoogleFonts.almarai(
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
