import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 🌟 إضافة مفتاح الفورم للتحكم بعمليات التحقق (Validation)
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // 🌟 حقل التأكيد
  final TextEditingController _uniIdController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingBuses = false;

  // 🌟 متغيرات التحكم بإظهار وإخفاء كلمة المرور
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedRole = 'student';
  String? _selectedBusId;
  List<Map<String, dynamic>> _busesList = [];

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    setState(() => _isFetchingBuses = true);
    try {
      final data = await Supabase.instance.client
          .from('buses')
          .select('id, bus_number');
      if (mounted) {
        setState(() {
          _busesList = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('🔥 خطأ في جلب الباصات: $e');
    } finally {
      if (mounted) setState(() => _isFetchingBuses = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // 🌟 إغلاق المراقب الجديد
    _uniIdController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // 🌟 التحقق التلقائي من جميع الشروط والقيود التي وضعناها في الحقول
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == 'driver' && _selectedBusId == null) {
      _showSnackBar('الرجاء اختيار الباص الذي ستقوده', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = res.user;

      if (user != null) {
        bool isApproved = (_selectedRole == 'student');

        final profileData = {
          'id': user.id,
          'name': _nameController.text.trim(),
          'role': _selectedRole,
          'is_approved': isApproved,
        };

        if (_selectedRole == 'student') {
          profileData['university_id'] = _uniIdController.text.trim();
        }

        await Supabase.instance.client.from('profiles').insert(profileData);

        if (_selectedRole == 'driver') {
          await Supabase.instance.client
              .from('buses')
              .update({'driver_id': user.id})
              .eq('id', _selectedBusId!);
        }

        if (!mounted) return;

        if (isApproved) {
          _showSnackBar(
            'تم إنشاء حساب الطالب بنجاح! يمكنك تسجيل الدخول الآن.',
            Colors.green,
          );
        } else {
          _showSnackBar(
            'تم التسجيل بنجاح! حسابك قيد المراجعة بانتظار تفعيل المشرف.',
            Colors.orange,
          );
        }

        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _showSnackBar('خطأ في التسجيل: ${e.message}', Colors.red);
    } catch (e) {
      _showSnackBar('حدث خطأ غير متوقع: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        centerTitle: true,
        backgroundColor: const Color(0xFF246BFD),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            // 🌟 تغليف العناصر بالـ Form لتفعيل الـ Validation
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الاسم الكامل مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      hintTextDirection: TextDirection.ltr,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'البريد الإلكتروني مطلوب';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🌟 حقل كلمة المرور مع القيود والإظهار/الإخفاء
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'كلمة المرور مطلوبة';
                      }
                      if (value.length < 8) {
                        return 'يجب أن لا تقل عن 8 أحرف';
                      }
                      if (!RegExp(
                        r'(?=.*[a-zA-Z])(?=.*[0-9])',
                      ).hasMatch(value)) {
                        return 'يجب أن تحتوي على أحرف وأرقام';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🌟 حقل تأكيد كلمة المرور
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمات المرور غير متطابقة!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'صفة الحساب:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('طالب'),
                          ),
                          DropdownMenuItem(
                            value: 'driver',
                            child: Text('سائق'),
                          ),
                          DropdownMenuItem(
                            value: 'supervisor',
                            child: Text('مشرف'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRole = newValue;
                              _uniIdController.clear();
                              _selectedBusId = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  if (_selectedRole == 'student') ...[
                    const SizedBox(height: 16),
                    // 🌟 حقل الرقم الجامعي مع تقييد بـ 6 أرقام
                    TextFormField(
                      controller: _uniIdController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'الرقم الجامعي',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (_selectedRole == 'student') {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرقم الجامعي مطلوب للطالب';
                          }
                          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                            return 'يجب أن يتكون من 6 أرقام بالضبط';
                          }
                        }
                        return null;
                      },
                    ),
                  ],

                  if (_selectedRole == 'driver') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'الباص المرتبط بك:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isFetchingBuses
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBusId,
                                hint: const Text('اضغط لاختيار الباص'),
                                isExpanded: true,
                                items: _busesList.map((bus) {
                                  return DropdownMenuItem<String>(
                                    value: bus['id'].toString(),
                                    child: Text('باص رقم ${bus['bus_number']}'),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedBusId = val),
                              ),
                            ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF246BFD),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'إنشاء الحساب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
