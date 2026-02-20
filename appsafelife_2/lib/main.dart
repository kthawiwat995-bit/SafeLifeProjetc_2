import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';      // เพราะมันวางอยู่ข้าง main.dart เลยเรียกได้เลย
import 'screen/signin.dart';      // เพราะมันอยู่ในโฟลเดอร์ screen ต้องระบุทางเดิ
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // เอาแถบ Debug มุมขวาบนออก
      title: 'App Safe Life',
      
      // --- ส่วนสำคัญ: ตั้งค่า Theme ให้เปลี่ยนตามมือถือ ---
      themeMode: ThemeMode.system, // ให้ถือตามการตั้งค่าของเครื่อง (Dark/Light)
      
      // ธีมสว่าง (Light Mode)
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      
      // ธีมมืด (Dark Mode)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // พื้นหลังดำสนิท
      ),

      // หน้าแรกที่ให้โชว์ (ต้องเป็น LoginScreen)
      home: const LoginScreen(), 
    );
  }
}