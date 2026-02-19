import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // สร้าง Controller ไว้รับค่า (สมมติว่าดึงค่าเก่ามาโชว์)
  final _nameController = TextEditingController(text: "John Doe");
  final _emailController = TextEditingController(text: "johndoe@gmail.com");
  final _phoneController = TextEditingController(text: "+66 123456789");
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text("User Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. รูปโปรไฟล์ + ปุ่มกล้อง
            Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                )
              ],
            ),
            const SizedBox(height: 40),

            // 2. ฟอร์มกรอกข้อมูล (ใช้ฟังก์ชันสร้างจะได้ไม่รก)
            _buildTextField("Full Name", _nameController, Icons.person_outline),
            _buildTextField("E-Mail", _emailController, Icons.email_outlined),
            _buildTextField("Phone No", _phoneController, Icons.phone_outlined),

            const SizedBox(height: 30),

            // 3. ปุ่ม Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: บันทึกข้อมูลลง Database
                  Navigator.pop(context); // บันทึกเสร็จแล้วปิดหน้านี้
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile Updated!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            // 4. ปุ่ม Change Password
            ElevatedButton(
              onPressed: () {
                _showChangePasswordSheet(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Change Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // Widget สร้างช่องกรอกข้อมูล (Reusable)
  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    // remove local controller declarations here and use _passController / _confirmController
    // if you want fresh values each time, call _passController.clear() and _confirmController.clear() before showing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          children: [
            TextField(controller: _passController, decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder())),
            TextField(controller: _confirmController, decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_passController.text == _confirmController.text) {
                // TODO: บันทึกข้อมูลลง Database
                Navigator.pop(context); // บันทึกเสร็จแล้วปิดหน้านี้
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password Updated!")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match!")),
                );
              }
            },
            child: const Text("SAVE"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("CANCEL"),
          ),
        ],
      ),
    );
  }
}