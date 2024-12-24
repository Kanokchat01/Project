import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ใช้สำหรับเลือกภาพจากแกลเลอรี
import 'dart:io'; // ใช้สำหรับจัดการไฟล์รูปภาพ

class NewPostPage extends StatefulWidget {
  final Function(String, File?) onPostCreated; // ฟังก์ชันสำหรับสร้างโพสต์
  const NewPostPage({super.key, required this.onPostCreated});

  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage; // ไฟล์ภาพที่เลือกจากแกลเลอรี่

  // ฟังก์ชันสำหรับเลือกภาพจากแกลเลอรี่
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // แปลงไฟล์ที่ได้เป็น File
      });
    } else {
      // ถ้าผู้ใช้ยกเลิกการเลือกภาพ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post',style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color.fromARGB(255, 34, 34, 161),
        iconTheme: const IconThemeData(color: Colors.white) // เปลี่ยนสี AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // จัดตำแหน่งเนื้อหาให้ชิดซ้าย
          children: [
            // กล่องข้อความสำหรับให้ผู้ใช้พิมพ์โพสต์
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'What\'s on your mind?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // มุมโค้งมน
                  borderSide: const BorderSide(color: Color.fromARGB(255, 34, 34, 161)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                hintStyle: TextStyle(color: Colors.grey[600]), // เปลี่ยนสีของ hint
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // ปุ่มสำหรับเลือกภาพ
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 34, 34, 161), // สีของปุ่ม
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // มุมโค้งมน
                ),
                padding: const EdgeInsets.symmetric(vertical: 10), // เพิ่มพื้นที่ภายในปุ่ม
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, color: Colors.white), // ไอคอนรูปภาพสีขาว
                  const SizedBox(width: 10),
                  const Text('', style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),

            // แสดงภาพที่เลือก (ถ้ามี)
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), // ทำมุมโค้งมนให้กับภาพ
                  child: Image.file(
                    _selectedImage!,
                    height: 150,
                    width: double.infinity, // ทำให้ภาพเต็มความกว้าง
                    fit: BoxFit.cover, // ให้ภาพเต็มพื้นที่
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ปุ่มสำหรับโพสต์ข้อความและรูปภาพ
            ElevatedButton(
              onPressed: () {
                if (_contentController.text.isNotEmpty || _selectedImage != null) {
                  widget.onPostCreated(_contentController.text, _selectedImage);
                  Navigator.pop(context); // กลับไปหน้า FeedPage หลังโพสต์ถูกสร้าง
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter some content or select an image.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // ให้ปุ่มเต็มความกว้าง
                backgroundColor: Color.fromARGB(255, 34, 34, 161), // สีของปุ่ม
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // มุมโค้งมน
                ),
              ),
              child: const Text('Create Post', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
