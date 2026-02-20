import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
class SOSMapPage extends StatefulWidget {
  const SOSMapPage({super.key});

  @override
  State<SOSMapPage> createState() => _SOSMapPageState();
}

class _SOSMapPageState extends State<SOSMapPage> {
  String _status = "เตรียมพร้อมแจ้งพิกัดฉุกเฉิน";
  bool _isLoading = false;
  final String _accessToken = "FzLNaCU3PeD1mQj/cYJlbjcW9FY1x+q2dZcMc0ahNTO/0rj5fgJdTR+k763BI3ZyZAWdCgz/HV1QVX5a5h/vrA2TEWgF5YCZuWoZdymLwkt6QYx8D2dErL2nPVzNkpZReH5PiAOShxlSzSfV7Aap1AdB04t89/1O/w1cDnyilFU=";
  final String _myUserId = "U8ad995faeaaa51451e0c31a42c959cb1";
  // --- ใส่ LINE Token ยาวๆ ของพี่ตรงนี้ ---
  final String _lineToken = "2009178883"; 

  Future<void> _sendSOS() async {
    setState(() { _isLoading = true; _status = "กำลังตรวจสอบสิทธิ์ GPS..."; });

    try {
      // 1. เช็กว่าเปิด Service GPS ในเครื่องหรือยัง
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _status = "❌ กรุณาเปิดตำแหน่ง (Location) ในหน้าตั้งค่าเครื่อง"; });
        _isLoading = false;
        return;
      }

      // 2. เช็กสิทธิ์การเข้าถึง (Permission)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _status = "❌ คุณปฏิเสธการเข้าถึง GPS"; });
          _isLoading = false;
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() { _status = "❌ GPS ถูกบล็อกถาวร กรุณาไปแก้ในตั้งค่าแอป"; });
        _isLoading = false;
        return;
      }

      // 3. ถ้าผ่านหมดแล้วค่อยดึงพิกัด
      setState(() { _status = "กำลังล็อกเป้าหมายพิกัด..."; });
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      String mapsLink = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";

      // 4. ส่ง Messaging API (ใช้ Token ที่พี่ได้จาก LINE OA)
      // หมายเหตุ: ตรงนี้ต้องเปลี่ยนเป็น API ของ Messaging API ถ้าพี่ใช้ Channel Access Token นะครับ
      final response = await http.post(
        Uri.parse('https://api.line.me/v2/bot/message/push'),
        headers: {
          'Authorization': 'Bearer $_accessToken', // ใช้ Token ยาวๆ ของพี่
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "to": _myUserId,
          "messages": [
            {
              "type": "text",
              "text": "🚨 SOS! แจ้งเหตุฉุกเฉิน\n📍 พิกัด: $mapsLink"
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        setState(() { _status = "✅ แจ้งพิกัดสำเร็จ!"; });
        launchUrl(Uri.parse('sms:1669?body=SOS! พิกัด: $mapsLink'));
      } else {
        setState(() { _status = "❌ API Error: ${response.statusCode}"; });
      }

    } catch (e) {
      setState(() { _status = "ข้อผิดพลาดระบบ: $e"; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // พื้นหลังดำสนิท อ่านง่ายไม่แสบตา
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ไอคอนหมุดแบบมีรัศมีเรืองแสง
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, size: 100, color: Colors.redAccent),
            ),
            const SizedBox(height: 30),
            const Text(
              "EMERGENCY SOS", 
              style: TextStyle(
                color: Colors.white, 
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5
              )
            ),
            const SizedBox(height: 15),
            Text(
              _status, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16)
            ),
            const SizedBox(height: 60),
            // ปุ่มกดทรงกลมขนาดใหญ่
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 15,
                  shadowColor: Colors.red.withOpacity(0.5),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("SOS", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "ส่งพิกัดไปยังศูนย์กู้ชีพและเบอร์ 1669", 
              style: TextStyle(color: Colors.white38, fontSize: 12)
            ),
          ],
        ),
      ),
    );
  }
}