import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class AIFirstAidPage extends StatefulWidget {
  const AIFirstAidPage({super.key});

  @override
  State<AIFirstAidPage> createState() => _AIFirstAidPageState();
}

class _AIFirstAidPageState extends State<AIFirstAidPage> {
  File? _image;
  String _result = "ยังไม่มีข้อมูลการวิเคราะห์";
  bool _isLoading = false;
  double _confidence = 0.0;

  // *** ใส่ API Key ของพี่ตรงนี้ ***
  final String _apiKey = "AIzaSyC8lfMWrxQrxQeyNnUg2yopuXjjoU-eboM"; 

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "รูปพร้อมแล้ว กดวิเคราะห์ได้เลย";
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;
    setState(() { _isLoading = true; _result = "AI กำลังวิเคราะห์..."; });

    try {
      final model = GenerativeModel(model: 'gemini-flash-latest', apiKey: _apiKey);
      final imageBytes = await _image!.readAsBytes();

      // --- วางทับตรงนี้ ---
      final prompt = TextPart("วิเคราะห์ว่านี่คือบาดแผลอะไร และบอกวิธีปฐมพยาบาล ถ้าไม่ใช่แผลให้บอกว่าขอภาพใหม่ ในรูปแบบ [Confidence: XX%]");
      
      final imagePart = DataPart('image/jpeg', imageBytes);
      
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      // --- จบตรงนี้ ---
      setState(() {
        _result = response.text ?? "วิเคราะห์ไม่ได้";
        final regExp = RegExp(r"\[Confidence:\s*(\d+)%\]");
        final match = regExp.firstMatch(_result);
        if (match != null) _confidence = double.parse(match.group(1)!) / 100;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _result = "Error: $e"; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("AI วิเคราะห์บาดแผล", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_image != null) Image.file(_image!, height: 250),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text("เลือกรูปแผล")),
            if (_image != null) ElevatedButton(onPressed: _analyzeImage, child: const Text("เริ่มวิเคราะห์")),
            const Divider(height: 40),
            if (_isLoading) const CircularProgressIndicator(),
            if (_confidence > 0) LinearProgressIndicator(value: _confidence),
            Padding(padding: const EdgeInsets.all(8.0), child: Text(_result)),
          ],
        ),
      ),
    );
  }
}