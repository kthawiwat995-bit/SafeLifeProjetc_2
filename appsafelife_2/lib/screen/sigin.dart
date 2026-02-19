import 'package:flutter/material.dart';
import 'signup.dart'; // เรียกใช้หน้า Signup
import 'home.dart';   // เรียกใช้หน้า Home
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = true;
  // ตัวควบคุมช่องกรอกชื่อ
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // เช็คโหมดมืด/สว่าง เพื่อปรับสี
  bool isDarkMode(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Logo
              const Center(
                child: Icon(Icons.volunteer_activism, size: 80, color: Color(0xFF4b68ff)),
              ),
              const SizedBox(height: 20),

              // 2. Text Welcome
              Text(
                "Welcome back,",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode(context) ? Colors.white : Colors.black,
                    ),
              ),
              const Text(
                "Discover Limitless Choices and Unmatched Convenience.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // 3. Form Fields - Username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Form Fields - Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: const Icon(Icons.visibility_off_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),

              // 5. Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFF4b68ff),
                        onChanged: (value) => setState(() => _rememberMe = value!),
                      ),
                      const Text("Remember Me"),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF4b68ff))),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // 6. ปุ่ม Sign In
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    signIn();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4b68ff),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),

              // 7. ปุ่ม Create Account
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () async {
                    // กดไปหน้าสมัครสมาชิก แล้วรอรับค่าชื่อกลับมา (result)
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );

                    // ถ้าได้ค่ากลับมา (แปลว่าสมัครเสร็จ) ให้เติมลงช่อง Username
                    if (result != null) {
                      setState(() {
                        _usernameController.text = result;
                      });
                      // แจ้งเตือนเล็กน้อย
                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("ยินดีต้อนรับคุณ $result กรุณาใส่รหัสผ่านเพื่อเข้าสู่ระบบ")),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDarkMode(context) ? Colors.grey : Colors.black),
                    foregroundColor: isDarkMode(context) ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Create Account"),
                ),
              ),
              const SizedBox(height: 30),

              // 8. Social Login Section
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Or Sign In With", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 20),

              // 9. Social Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.g_mobiledata, isDarkMode(context)),
                  const SizedBox(width: 20),
                  _buildSocialButton(Icons.facebook, isDarkMode(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สร้างปุ่ม Social (แยกออกมาให้อ่านง่าย)
  Widget _buildSocialButton(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500),
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
      ),
      child: Icon(
        icon,
        color: isDark ? Colors.white : Colors.black,
        size: 30,
      ),
    );
  }
  Future<void> signIn() async {
    // 1. สั่งโชว์ Loading (ถ้ามีตัวแปร loading)
    // setState(() => _isLoading = true); 

    try {
      // 2. ส่งตั๋วไปตรวจกับ Firebase (จุดสำคัญที่ขาดไป!)
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(), // ต้องตรงกับชื่อตัวแปร controller ของนาย
        password: _passwordController.text.trim(),
      );

      // 3. ถ้าผ่าน: ย้ายไปหน้า Home
      debugPrint("ล็อกอินถูกต้อง! ยินดีต้อนรับ");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => HomeScreen(
        username: _usernameController.text, // ส่งอีเมลที่กรอก ไปโชว์เป็นชื่อเล่นก่อน
      ),
    ), 
      );

    } on FirebaseAuthException catch (e) {
      // 4. ถ้าไม่ผ่าน: ฟ้อง Error (เช่น รหัสผิด, ไม่มี user นี้)
      String message = 'ล็อกอินล้มเหลว';
      if (e.code == 'user-not-found') {
        message = 'ไม่พบอีเมลนี้ในระบบ';
      }
      else if (e.code == 'wrong-password') {
        message = 'รหัสผ่านไม่ถูกต้อง';
      }
      else if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } 
    finally {
    if (mounted) setState(() => _isLoading = false); }
  }
}