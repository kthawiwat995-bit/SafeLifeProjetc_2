import 'package:flutter/material.dart';

// 1. Model: สร้างคลาสง่ายๆ สำหรับเก็บข้อมูลข้อความ
class ChatMessage {
  final String text;
  final bool isUser; // true = เราพิมพ์, false = บอท/หมอ ตอบ
  final DateTime time;
  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controller สำหรับรับข้อความ และ เลื่อนหน้าจอลงล่างสุด
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // รายการข้อความ (Mock Data ไว้ก่อน)
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "สวัสดีครับ มีอาการเจ็บป่วยหรืออุบัติเหตุอะไรให้ช่วยประเมินไหมครับ?",
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  // ฟังก์ชันจำลองการส่งข้อความ (ส่วนนี้แหละที่จะเอาไปต่อ API Python)
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // 1. เพิ่มข้อความฝั่งเรา (User)
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();

    // 2. จำลองการเรียก API (เพื่อนของคุณ)
    // ตรงนี้คือจุดที่คุณจะยิง Request ไปหา Python
    Future.delayed(const Duration(seconds: 1), () {
      // จำลองว่าได้รับคำตอบกลับมา
      setState(() {
        _messages.add(ChatMessage(
          text: "รับทราบครับ ระบบกำลังประเมินอาการ '$text' เบื้องต้น...",
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ดึงสี Theme มาจากรูป Screenshot ของคุณ
    final Color primaryColor = const Color(0xFF7E57C2); // สีม่วงไอคอน Home
    final Color bgColor = const Color(0xFFF9F9F9); // สีพื้นหลังเทาอ่อนๆ

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SafeLife Chat",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ส่วนแสดงรายการข้อความ
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, primaryColor);
              },
            ),
          ),
          
          // ส่วนช่องพิมพ์ข้อความ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "พิมพ์อาการของคุณ...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                const SizedBox(width: 12),
                // ปุ่มส่ง
                GestureDetector(
                  onTap: () => _handleSubmitted(_textController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor, // สีม่วงตาม Theme
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget สร้าง Bubble ข้อความ
  Widget _buildMessageBubble(ChatMessage msg, Color primaryColor) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser ? primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            if (!msg.isUser) // ใส่เงาเฉพาะข้อความบอท ให้ดูเหมือน Card ในหน้า Home
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}