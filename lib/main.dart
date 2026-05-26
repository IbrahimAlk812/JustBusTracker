import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // 🌟 مكتبة الخطوط

// مسارات الشاشات
import 'package:just_bus_tracker/screens/auth/login_screen.dart';
import 'package:just_bus_tracker/screens/student/student_home_screen.dart';
import 'package:just_bus_tracker/screens/supervisor/supervisor_dashboard.dart';
import 'package:just_bus_tracker/screens/driver/driver_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف البيئة
  await dotenv.load(fileName: ".env");

  // تهيئة الاتصال بقاعدة البيانات
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 اللون الأزرق الحيوي المستوحى من صورتك المرفقة
    const Color primaryBlue = Color(0xFF246BFD);
    const Color secondaryBlue = Color(0xFF5A8BFF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Just Bus Tracker',

      theme: ThemeData(
        useMaterial3: true,
        // لون الخلفية العام لجميع الشاشات
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: secondaryBlue,
        ),

        // 🌟 توحيد الخطوط (استخدام خط Almarai)
        textTheme: GoogleFonts.almaraiTextTheme(Theme.of(context).textTheme),

        // شكل الشريط العلوي (AppBar)
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: GoogleFonts.almarai(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        // شكل البطاقات (Cards)
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withValues(
            alpha: 0.15,
          ), // تخفيف الظل قليلاً ليتناسب مع اللون الفاتح
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.only(bottom: 15),
        ),

        // شكل الأزرار (ElevatedButtons)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.almarai(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // شريط التنقل السفلي (Bottom Navigation Bar)
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.almarai(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.almarai(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),

        // حقول الإدخال (TextFormFields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          labelStyle: GoogleFonts.almarai(color: Colors.grey.shade600),
        ),
      ),

      // الصفحة الافتراضية للتجربة
      home: const LoginScreen(),
    );
  }
}
