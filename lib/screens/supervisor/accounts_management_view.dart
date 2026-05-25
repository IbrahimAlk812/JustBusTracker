import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountsManagementView extends StatefulWidget {
  const AccountsManagementView({super.key});

  @override
  State<AccountsManagementView> createState() => _AccountsManagementViewState();
}

class _AccountsManagementViewState extends State<AccountsManagementView> {
  // دالة لتفعيل الحساب (تغيير is_approved إلى true)
  Future<void> _approveAccount(String userId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_approved': true})
          .eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تفعيل الحساب بنجاح! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء التفعيل.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة لحذف بروفايل الحساب (الحظر النهائي ومنع الدخول)
  Future<void> _deleteAccountProfile(String userId) async {
    try {
      await Supabase.instance.client.from('profiles').delete().eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف وإلغاء صلاحيات الحساب بنجاح.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء حذف الحساب.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // نافذة تأكيد قبل الحذف لحماية البيانات
  void _confirmDelete(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'تأكيد الحذف القيادي',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف حساب ($userName) وإلغاء صلاحياته تماماً من النظام؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccountProfile(userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'نعم، احذف',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // عدد الأقسام
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'إدارة صلاحيات الحسابات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(text: 'طلبات المعلقة ⏳'),
              Tab(text: 'الحسابات النشطة 🟢'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAccountsList(
              isApprovedFilter: false,
            ), // القسم الأول: الحسابات المعلقة
            _buildAccountsList(
              isApprovedFilter: true,
            ), // القسم الثاني: الحسابات المفعّلة
          ],
        ),
      ),
    );
  }

  // بناء القائمة الحية للحسابات بناءً على الفلتر المختار
  Widget _buildAccountsList({required bool isApprovedFilter}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('is_approved', isApprovedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              isApprovedFilter
                  ? 'لا يوجد حسابات نشطة حالياً.'
                  : 'لا يوجد طلبات تفعيل معلقة حالياً.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final accounts = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final user = accounts[index];
            final String userId = user['id'].toString();
            final String name = user['name'] ?? 'مستخدم غير مسمى';
            final String role = user['role'] ?? 'student';

            // تحديد النمط البصري حسب نوع الدور (طالب، سائق، مشرف)
            IconData roleIcon;
            Color roleColor;
            String roleText;

            if (role == 'driver') {
              roleIcon = Icons.drive_eta;
              roleColor = Colors.orange;
              roleText = 'سائق';
            } else if (role == 'supervisor') {
              roleIcon = Icons.admin_panel_settings;
              roleColor = Colors.red;
              roleText = 'مشرف';
            } else {
              roleIcon = Icons.school;
              roleColor = Colors.blue;
              roleText = 'طالب';
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: roleColor.withOpacity(0.1),
                        radius: 26,
                        child: Icon(roleIcon, color: roleColor, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                roleText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // الأزرار التفاعلية بناءً على نوع القسم (معلق أم نشط)
                      if (!isApprovedFilter) ...[
                        // أزرار الحسابات المعلقة
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          ),
                          onPressed: () => _approveAccount(userId),
                          tooltip: 'تفعيل وتعميد الحساب',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 30,
                          ),
                          onPressed: () => _confirmDelete(userId, name),
                          tooltip: 'رفض وحذف الطلب',
                        ),
                      ] else ...[
                        // أزرار الحسابات النشطة (نسمح بحذف السائق أو الطالب عند الحاجة، ونحمي المشرف من حذف نفسه بالخطأ)
                        if (userId !=
                            Supabase.instance.client.auth.currentUser?.id)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                              size: 28,
                            ),
                            onPressed: () => _confirmDelete(userId, name),
                            tooltip: 'إلغاء وتجميد الحساب',
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
