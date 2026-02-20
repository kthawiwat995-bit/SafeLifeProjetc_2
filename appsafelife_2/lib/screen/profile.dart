import 'package:flutter/material.dart';
import 'signin.dart'; // เรียกหน้า LoginScreen
import 'edit_profile.dart'; // เรียกหน้า EditProfileScreen

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State สำหรับ Toggle Switch
  bool _isNotificationOn = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // 1. User Info Card (ส่วนหัวยังคงเป็นตัวอักษร J เหมือนเดิมตามที่เคยแก้ไว้)
            _buildUserHeader(isDark, cardColor),
            
            const SizedBox(height: 30),

            // 2. Menu Options
            
            // --- เมนู User Profile (ใช้แบบไอคอนคนปกติ) ---
            _buildMenuTile(
              icon: Icons.person_outline,
              title: "User Profile",
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const EditProfileScreen())
                );
              },
            ),
            
            _buildMenuTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              isDark: isDark,
              onTap: () => _showChangePasswordSheet(context),
            ),
            
            _buildMenuTile(
              icon: Icons.help_outline,
              title: "FAQs",
              isDark: isDark,
              onTap: () { /* Navigate to FAQs */ },
            ),

            // 3. Notification Switch
            _buildNotificationTile(isDark, primaryColor),

            const SizedBox(height: 30),

            // 4. Support Card
            _buildSupportCard(isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  // ==================== WIDGET COMPONENTS ====================

  // ส่วนหัว (Header) -> ยังคงเป็นตัวอักษรแรก (J) ตามดีไซน์
  Widget _buildUserHeader(bool isDark, Color cardColor) {
    String firstLetter = widget.username.isNotEmpty ? widget.username[0].toUpperCase() : "?";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, 
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2), 
            ),
            alignment: Alignment.center,
            child: Text(
              firstLetter, 
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text(
                  widget.username,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
          ),
        ],
      ),
    );
  }

  // เมนูปกติ (Reusable Widget)
  Widget _buildMenuTile({required IconData icon, required String title, required bool isDark, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: isDark ? Colors.white : Colors.black87),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // เมนู Notification
  Widget _buildNotificationTile(bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: SwitchListTile(
        activeColor: primaryColor,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : Colors.black87),
        ),
        title: const Text("Push Notification", style: TextStyle(fontWeight: FontWeight.w600)),
        value: _isNotificationOn,
        onChanged: (bool value) => setState(() => _isNotificationOn = value),
      ),
    );
  }

  // Support Card
  Widget _buildSupportCard(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            "If you have any other query you can reach out to us.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text("Contact Support", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // หน้าต่างเปลี่ยนรหัสผ่าน
  void _showChangePasswordSheet(BuildContext context) {
    final passController = TextEditingController();
    final confirmController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Change Password", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: passController, obscureText: true, decoration: InputDecoration(labelText: "New Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_outline))),
              const SizedBox(height: 15),
              TextField(controller: confirmController, obscureText: true, decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_reset))),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Changed Successfully!")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("SAVE PASSWORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // ฟังก์ชัน Logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text("Yes, Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}