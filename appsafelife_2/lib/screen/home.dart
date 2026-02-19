import 'package:flutter/material.dart';
import 'dart:async';
import 'profile.dart';
import 'chatbot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // --- State Variables ---
  int _selectedIndex = 0;
  int _newsIndex = 0;
  
  // --- Controllers ---
  late final PageController _newsController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _newsTimer;

  // --- Mock Data (เตรียมไว้ต่อ API ในอนาคต) ---
  final List<Map<String, dynamic>> _newsData = [
    {"title": "PM 2.5 Alert", "desc": "High pollution levels. Wear a mask.", "color": Colors.orange, "icon": Icons.cloud_off},
    {"title": "Heavy Rain", "desc": "Storm expected. Stay indoors.", "color": Colors.blue, "icon": Icons.thunderstorm},
    {"title": "Emergency", "desc": "Nearest hospital is 2km away.", "color": Colors.red, "icon": Icons.local_hospital},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _startNewsAutoScroll();
  }

  void _initControllers() {
    // 1. News Controller
    _newsController = PageController(viewportFraction: 0.85);

    // 2. SOS Pulse Animation (หายใจเข้า-ออก)
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startNewsAutoScroll() {
    _newsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_newsIndex < _newsData.length - 1) {
        _newsIndex++;
      } else {
        _newsIndex = 0;
      }
      if (_newsController.hasClients) {
        _newsController.animateToPage(_newsIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    _newsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // หน้าต่างๆ ของ App
    final List<Widget> pages = [
      _buildHomeBody(isDark, primaryColor), // หน้าหลัก
      const Center(child: Text("Google Map Page")),
      const Center(child: Text("QR Scan Page")),
      const Center(child: Text("AI Consult Page")),
      ProfileScreen(username: widget.username),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: _buildBottomNavBar(isDark, primaryColor),
    );
  }

  // ==================== WIDGET COMPONENT ZONES ====================

  // 1. หน้า Home หลัก (รวมทุกอย่าง)
  Widget _buildHomeBody(bool isDark, Color primary) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(isDark),
          const SizedBox(height: 40),
          _buildSOSButton(),
          const SizedBox(height: 50),
          _buildStatusCard(isDark, primary),
          const SizedBox(height: 20),
          _buildNewsSection(),
          const SizedBox(height: 20),
          _buildLocationBar(isDark),   
          const SizedBox(height: 20),
          _buildQuickActions(isDark),  
          const SizedBox(height: 40),  
          _buildSafetyTips(isDark), 
          const SizedBox(height: 40),
          _buildReportButton(isDark), 
        const SizedBox(height: 100),
        ],
      ),
    );
  }

  // 2. ส่วนหัว (Header)
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ส่วนชื่อ: ใช้ FutureBuilder ดึงชื่อจริงจากฐานข้อมูล
          Expanded( 
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users') // ไปที่คอลเลกชัน users
                  .doc(FirebaseAuth.instance.currentUser?.uid) // ดึงตาม ID ของเรา
                  .get(),
              builder: (context, snapshot) {
                // ระหว่างรอโหลดข้อมูล
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading...", style: TextStyle(color: Colors.grey, fontSize: 20));
                }

                // ดึงข้อมูลออกมา (ถ้ามี)
                String displayName = "Guest";
                if (snapshot.hasData && snapshot.data!.exists) {
                  // 'username' ต้องตรงกับที่ตั้งไว้ใน Firestore (ตัวเล็ก/ใหญ่มีผล)
                  displayName = snapshot.data!['username'] ?? "No Name"; 
                }

                // แสดงผลชื่อ
                return Text(
                  displayName, 
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // ด้านขวา: วงกลมตัวอักษรแรก (ใช้ตัวแรกของอีเมลไปก่อนก็ได้)
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.username.isNotEmpty ? widget.username[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. ปุ่ม SOS (แยกออกมาเพื่อความ clean)
  Widget _buildSOSButton() {
    return Center(
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🚨 SOS SENT!"), backgroundColor: Colors.red),
            );
          },
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5E57), Color(0xFFD63031)],
                begin: Alignment.topLeft, end: Alignment.bottomRight
              ),
              boxShadow: [
                BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.touch_app, color: Colors.white, size: 50),
                Text("SOS", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. การ์ดสถานะ (Status Card)
  Widget _buildStatusCard(bool isDark, Color primary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50,
        border: Border.all(
        color: isDark ? Colors.green.withOpacity(0.3) : Colors.transparent,
        width: 1.5,
        
  ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
    BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.security, color: Colors.green),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Current Status", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text("YOU ARE SAFE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  // 5. ส่วนข่าวสาร (News Section)
  Widget _buildNewsSection() {
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _newsController,
        itemCount: _newsData.length,
        itemBuilder: (context, index) {
          final news = _newsData[index];
          return _buildNewsItem(news['title'], news['desc'], news['color'], news['icon']);
        },
      ),
    );
  }

  // 6. ชิ้นข่าวสารย่อย (News Item)
  Widget _buildNewsItem(String title, String desc, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          Icon(icon, color: color, size: 36),
        ],
      ),
    );
  }

  // 7. Navbar
  Widget _buildBottomNavBar(bool isDark, Color primary) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? Colors.black : Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner, size: 30), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }

  // 1. แถบ Location
  Widget _buildLocationBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Location",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  "Siam Paragon, Bangkok",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_location, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 2. ปุ่มเมนูลัด
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Assist",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _actionBtn("Police", Icons.local_police, Colors.indigo, () {}),
              _actionBtn("Ambulance", Icons.medical_services, Colors.redAccent, () {}),
              _actionBtn("Siren", Icons.campaign, Colors.orange, () {}),
              _actionBtn("Flashlight", Icons.flashlight_on, Colors.yellow.shade700, () {}),
            ],
          ),
        ],
      ),
    );
  }
  // 3. ตัวช่วยสร้างปุ่มกลม
  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  // ==================== SAFETY GUIDES ZONE ====================

  Widget _buildSafetyTips(bool isDark) {
    // ข้อมูลจำลอง (แก้ไขง่ายตรงนี้เลย)
    final List<Map<String, dynamic>> guides = [
      {
        "title": "First Aid Basics",
        "desc": "CPR, Burn treatment, and choking.",
        "icon": Icons.healing,
        "color": Colors.redAccent,
      },
      {
        "title": "Self Defense",
        "desc": "Basic moves to protect yourself.",
        "icon": Icons.sports_martial_arts,
        "color": Colors.orange,
      },
      {
        "title": "Fire Emergency",
        "desc": "Exit plans and using extinguishers.",
        "icon": Icons.fire_extinguisher,
        "color": Colors.deepOrange,
      },
      {
        "title": "Earthquake Safety",
        "desc": "Drop, Cover, and Hold On.",
        "icon": Icons.waves, // หรือใช้ Icons.landscape
        "color": Colors.brown,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Safety Guides",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {}, 
                child: const Text("See All"),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // วนลูปสร้างรายการ (ไม่ต้องเขียนซ้ำเยอะ)
          ...guides.map((guide) => _buildGuideCard(
                isDark,
                guide["title"],
                guide["desc"],
                guide["icon"],
                guide["color"],
              )),
        ],
      ),
    );
  }

  // ตัวสร้างการ์ดแต่ละอัน
  Widget _buildGuideCard(bool isDark, String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // เว้นระยะห่างแต่ละการ์ด
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // ไอคอนด้านซ้าย
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          
          // ข้อความตรงกลาง
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // ลูกศรขวา
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }
  Widget _buildReportButton(bool isDark) { // <--- ต้องมี (bool isDark) ตรงนี้ครับ
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // ใส่คำสั่งไปหน้าแจ้งเหตุตรงนี้
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        // เปลี่ยนเป็นไอคอนมาตรฐาน (Icons.report_problem) 
        icon: Icon(
          Icons.report_problem, 
          color: isDark ? Colors.white70 : Colors.black87
        ),
        label: Text(
          "Report Incident",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}