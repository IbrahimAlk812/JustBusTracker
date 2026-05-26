import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/auth/login_screen.dart'; // 🌟 تأكد من مسار شاشة تسجيل الدخول لديك

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _isDarkMode = false; // 🌟 متغير جديد للتحكم بالمظهر

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        setState(() => userData = data);
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;

    // 🌟 التوجيه المباشر والآمن لشاشة تسجيل الدخول
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'حسابي',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF246BFD),
                    child: Icon(Icons.person, size: 55, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userData?['name'] ?? 'اسم الطالب غير متوفر',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الرقم الجامعي: ${userData?['university_id'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 30),

                  // صندوق الخيارات والإعدادات
                  // صندوق الخيارات والإعدادات
                  Container(
                    decoration: BorderRadius.circular(15).cardStyle(),
                    child: Column(
                      children: [
                        // 🌟 الصق الكود هنا (هذا هو الكود الجديد الذي يعوض السطر القديم)
                        _buildSettingTile(
                          Icons.dark_mode,
                          'المظهر الداكن',
                          trailing: Switch(
                            value: _isDarkMode,
                            activeColor: const Color(0xFF246BFD),
                            onChanged: (val) {
                              setState(() => _isDarkMode = val);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'سيتم تفعيل الوضع الداكن بالكامل في التحديثات القادمة!',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // 🌟 نهاية الكود الجديد
                        const Divider(height: 1),
                        _buildSettingTile(
                          Icons.info_outline,
                          'عن التطبيق',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _buildSettingTile(
                          Icons.logout,
                          'تسجيل الخروج',
                          iconColor: Colors.red,
                          textColor: Colors.red,
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title, {
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: iconColor != null
          ? Icon(icon, color: iconColor)
          : Icon(icon, color: const Color(0xFF246BFD)),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        textAlign: TextAlign.right,
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// إضافة Extension سريعة لتنسيق الـ Container كبطاقة
extension CardDecoration on BorderRadius {
  BoxDecoration cardStyle() => BoxDecoration(
    color: Colors.white,
    borderRadius: this,
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
    ],
  );
}
