import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 1. สร้าง Class สำหรับเก็บข้อมูลแต่ละข้อความ
class ChatMessage {
  final String text;
  final bool isUser; // true = คนพิมพ์, false = AI
  ChatMessage({required this.text, required this.isUser});
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // สำหรับควบคุมการเลื่อนจอ
  
  // 2. ใช้ List เก็บประวัติแชทแทน String เดี่ยวๆ (ใส่ข้อความต้อนรับไว้เลย)
  final List<ChatMessage> _messages = [
    ChatMessage(text: "สวัสดีครับ พิมพ์อธิบายลักษณะแผล หรืออาการบาดเจ็บ เพื่อรับคำแนะนำได้เลยครับ 🩺", isUser: false)
  ];
  
  bool _isLoading = false;
  final String _hfToken = ""; // ใส่ Token HF ของพี่ตรงนี้

  Future<void> _getAiAdvice() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    // 3. เอาข้อความที่คนพิมพ์ ยัดใส่ List แล้วล้างช่องพิมพ์
    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom(); // สั่งเลื่อนจอลงล่างสุด

    try {
      final url = Uri.parse("https://router.huggingface.co/v1/chat/completions");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $_hfToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "meta-llama/Llama-3.2-3B-Instruct",
          "messages": [
            {
              "role": "system",
              "content": "คุณเป็นผู้เชี่ยวชาญด้านการปฐมพยาบาลเบื้องต้น ให้คำแนะนำที่ถูกต้อง รวดเร็ว และเป็นภาษาไทย"
            },
            {
              "role": "user",
              "content": "อาการคือ: $userText \nช่วยบอกประเภทแผลและวิธีปฐมพยาบาลเบื้องต้นเป็นข้อๆ"
            }
          ],
          "max_tokens": 500,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        
        setState(() { 
          // 4. เอาคำตอบ AI ยัดใส่ List
          final aiText = data['choices'][0]['message']['content']; 
          _messages.add(ChatMessage(text: aiText.trim(), isUser: false));
        });
      } else {
        setState(() { 
          _messages.add(ChatMessage(text: "⚠️ ขัดข้อง (Code: ${response.statusCode})", isUser: false));
        });
      }
    } catch (e) {
      setState(() { 
        _messages.add(ChatMessage(text: "🔌 เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่ครับ", isUser: false));
      });
    } finally {
      setState(() { 
        _isLoading = false; 
      });
      _scrollToBottom();
    }
  }

  // ฟังก์ชันช่วยเลื่อนหน้าจอลงมาล่างสุดเวลามีข้อความใหม่
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("💬 ระบบปรึกษาการปฐมพยาบาล"),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          // พื้นที่แสดงแชท
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.isUser;
                
                return Align(
                  // ฝั่งขวา (User) และ ฝั่งซ้าย (AI)
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75, // กรอบกว้างสุด 75% ของจอ
                    ),
                    decoration: BoxDecoration(
                      // คนพิมพ์สีฟ้า, AI สีเทาอ่อน
                      color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ตัวแสดงสถานะตอน AI กำลังคิด
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("AI กำลังพิมพ์...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            
          // พื้นที่พิมพ์ข้อความด้านล่างสุด
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null, // พิมพ์ยาวได้ บรรทัดจะขยายเอง
                    decoration: InputDecoration(
                      hintText: "พิมพ์อธิบายอาการที่นี่...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _getAiAdvice,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}