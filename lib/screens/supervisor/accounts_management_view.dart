import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_bus_tracker/screens/auth/login_screen.dart';

class AccountsManagementView extends StatelessWidget {
  const AccountsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'إدارة الحسابات والصلاحيات',
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildMenuCard(
                  context,
                  'الحسابات النشطة',
                  Icons.groups_rounded,
                  Colors.blue,
                  const ActiveAccountsScreen(),
                ),
                _buildMenuCard(
                  context,
                  'حسابات تحت المراقبة',
                  Icons.warning_amber_rounded,
                  Colors.orange,
                  const WarnedAccountsScreen(),
                ),
                _buildMenuCard(
                  context,
                  'الحسابات المحظورة',
                  Icons.block,
                  Colors.red,
                  const BannedAccountsScreen(),
                ),
                _buildMenuCard(
                  context,
                  'حسابي الشخصي',
                  Icons.manage_accounts,
                  Colors.teal,
                  const SupervisorProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget destination,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      ),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 30,
              child: Icon(icon, color: color, size: 35),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. شاشة الحسابات النشطة (مقسمة لعلامات تبويب)
// ==========================================
class ActiveAccountsScreen extends StatelessWidget {
  const ActiveAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الحسابات النشطة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF246BFD),
          bottom: const TabBar(
            labelColor: Colors.white, // 🌟 لون النص للتبويب المحدد
            unselectedLabelColor:
                Colors.white70, // 🌟 لون النص للتبويبات غير المحددة
            indicatorColor: Colors.white,
            indicatorWeight: 3, // جعل الخط السفلي أعرض قليلاً لمظهر أجمل
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: 'الطلاب'),
              Tab(text: 'السائقين'),
              Tab(text: 'المشرفين'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AccountsListFetcher(role: 'student'),
            _AccountsListFetcher(role: 'driver'),
            _AccountsListFetcher(role: 'supervisor'),
          ],
        ),
      ),
    );
  }
}

class _AccountsListFetcher extends StatelessWidget {
  final String role;
  const _AccountsListFetcher({required this.role});

  Future<List<Map<String, dynamic>>> _fetchAccounts() async {
    return await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('role', role)
        .eq('is_banned', false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAccounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('لا يوجد حسابات حالياً'));

        final accounts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final acc = accounts[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(
                  acc['name'] ?? 'بدون اسم',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  acc['university_id']?.toString() ?? acc['email'] ?? '',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 2. شاشة الحسابات تحت المراقبة (مخالفات الغياب)
// ==========================================
class WarnedAccountsScreen extends StatefulWidget {
  const WarnedAccountsScreen({super.key});
  @override
  State<WarnedAccountsScreen> createState() => _WarnedAccountsScreenState();
}

class _WarnedAccountsScreenState extends State<WarnedAccountsScreen> {
  Future<List<Map<String, dynamic>>> _fetchWarnedAccounts() async {
    return await Supabase.instance.client
        .from('profiles')
        .select()
        .gt('no_show_warnings', 0)
        .eq('is_banned', false)
        .eq('role', 'student');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'تحت المراقبة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWarnedAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(
              child: Text('النظام نظيف! لا توجد حسابات عليها مخالفات.'),
            );

          final accounts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              final warnings = acc['no_show_warnings'];
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        warnings.toString(),
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      acc['name'] ?? 'بدون اسم',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'الرقم الجامعي: ${acc['university_id'] ?? 'غير مدرج'}\nلديه ($warnings) إنذار بسبب حجز مقعد وعدم الركوب.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    isThreeLine: true,
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

// ==========================================
// 3. شاشة الحسابات المحظورة (Is Banned)
// ==========================================
class BannedAccountsScreen extends StatefulWidget {
  const BannedAccountsScreen({super.key});
  @override
  State<BannedAccountsScreen> createState() => _BannedAccountsScreenState();
}

class _BannedAccountsScreenState extends State<BannedAccountsScreen> {
  Future<List<Map<String, dynamic>>> _fetchBannedAccounts() async {
    return await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('is_banned', true);
  }

  Future<void> _unbanUser(String userId) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'is_banned': false, 'no_show_warnings': 0})
        .eq('id', userId);
    setState(() {}); // لتحديث القائمة
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم فك الحظر عن الحساب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'الحسابات المحظورة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBannedAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(child: Text('لا يوجد حسابات محظورة حالياً.'));

          final accounts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.block,
                      color: Colors.red,
                      size: 30,
                    ),
                    title: Text(
                      acc['name'] ?? 'بدون اسم',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: Text('تم الحظر التلقائي لتجاوز 3 إنذارات غياب.'),
                    trailing: ElevatedButton(
                      onPressed: () => _unbanUser(acc['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                      ),
                      child: const Text('فك الحظر'),
                    ),
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

// ==========================================
// 4. شاشة حساب المشرف (تسجيل الخروج)
// ==========================================
// ==========================================
// 4. شاشة حساب المشرف (مطابقة لتصميم الطالب والسائق)
// ==========================================
class SupervisorProfileScreen extends StatefulWidget {
  const SupervisorProfileScreen({super.key});

  @override
  State<SupervisorProfileScreen> createState() =>
      _SupervisorProfileScreenState();
}

class _SupervisorProfileScreenState extends State<SupervisorProfileScreen> {
  String _name = 'جاري التحميل...';
  String _email = '';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _email = user.email ?? '';
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
        if (res != null && mounted) {
          setState(() {
            _name = res['name']?.toString() ?? 'مشرف النظام';
          });
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
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
        backgroundColor: const Color(0xFF246BFD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              color: const Color(0xFFF5F7FA),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF246BFD),
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  Text(
                    'حساب الإدارة والمراقبة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: SwitchListTile(
                        value: _isDarkMode,
                        onChanged: (val) => setState(() => _isDarkMode = val),
                        title: const Text(
                          'المظهر الداكن',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        secondary: const Icon(
                          Icons.dark_mode,
                          color: Color(0xFF246BFD),
                        ),
                        activeColor: const Color(0xFF246BFD),
                      ),
                    ),
                    const Divider(height: 1),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: Color(0xFF246BFD),
                        ),
                        title: const Text(
                          'عن التطبيق',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                    ),
                    const Divider(height: 1),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onTap: () => _logout(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
