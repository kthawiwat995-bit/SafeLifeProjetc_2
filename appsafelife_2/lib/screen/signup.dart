import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. สร้าง user ใน Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. บันทึกข้อมูลลง Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'username': _usernameController.text.trim(),
            'fullName': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'dob': _dobController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 3. Sign out เพื่อให้ user ต้อง login ใหม่ที่หน้า signin
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างบัญชีสำเร็จ!')));

      // 4. ส่ง email กลับไปหน้า signin เพื่อ auto-fill
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, _emailController.text.trim());
        }
      });
    } on FirebaseAuthException catch (e) {
      String message = 'สมัครสมาชิกล้มเหลว';
      if (e.code == 'email-already-in-use') {
        message = 'อีเมลนี้ถูกใช้งานแล้ว';
      } else if (e.code == 'weak-password') {
        message = 'รหัสผ่านไม่ปลอดภัยเพียงพอ';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Sign up to get started!",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Username
                _buildInputField(
                  controller: _usernameController,
                  label: "Username",
                  icon: Icons.account_circle_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'กรุณาตั้ง Username';
                    if (value.length < 4) return 'Username ต้องยาว 4 ตัวขึ้นไป';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full Name
                _buildInputField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'กรุณากรอกชื่อ-นามสกุล';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  validator: (value) {
                    if (_selectedDate == null) return 'กรุณาเลือกวันเกิด';
                    int age = _calculateAge(_selectedDate!);
                    if (age < 7) {
                      return 'ขออภัย อายุต้อง 7 ปีขึ้นไป (อายุของคุณ: $age ปี)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                _buildInputField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'กรุณากรอกเบอร์โทร';
                    if (value.length < 9) return 'เบอร์โทรไม่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                _buildInputField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'รูปแบบอีเมลไม่ถูกต้อง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                _buildInputField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'กรุณาตั้งรหัสผ่าน';
                    if (value.length < 8) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'ต้องมีตัวพิมพ์ใหญ่ (A-Z) อย่างน้อย 1 ตัว';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'ต้องมีตัวพิมพ์เล็ก (a-z) อย่างน้อย 1 ตัว';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'ต้องมีตัวเลข (0-9) อย่างน้อย 1 ตัว';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  "* รหัสผ่านต้องมีความยาว 8 ตัวขึ้นไป ประกอบด้วยตัวพิมพ์ใหญ่ ตัวพิมพ์เล็ก และตัวเลข",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}