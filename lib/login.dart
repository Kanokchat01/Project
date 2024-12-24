import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'feed.dart'; // นำเข้าหน้า timeline
import 'register.dart'; // นำเข้าหน้าสมัครสมาชิก

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // ตรวจสอบว่าชื่อผู้ใช้และรหัสผ่านถูกกรอกหรือไม่
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    // ส่งคำขอไปยัง API เพื่อตรวจสอบการล็อกอิน
    try {
      final response = await http.post(
        Uri.parse('http://192.168.213.1/login.php'), // URL ของ API
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == 'success' && data['userId'] != null) {
          int? userId = int.tryParse(data['userId'].toString()); // ตรวจสอบว่า userId มีค่าและเป็นตัวเลข
          
          if (userId != null) {
            // ถ้าล็อกอินสำเร็จ ส่ง userId ไปยัง FeedPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FeedPage(userId: userId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid user ID')),
            );
          }
        } else {
          // แสดงข้อความแจ้งเตือนถ้าล็อกอินไม่สำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${data['message']}')),
          );
        }
      } else {
        // แสดงข้อผิดพลาดถ้าพบปัญหากับเซิร์ฟเวอร์
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error, please try again later')),
        );
      }
    } catch (e) {
      // จัดการข้อผิดพลาดเช่นกรณีไม่สามารถติดต่อ API ได้
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg1.png'), // เปลี่ยนเป็น path ของภาพที่ต้องการใช้
            fit: BoxFit.cover, // ปรับให้เต็มพื้นที่
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                // ลบบรรทัดนี้ออกเพื่อเอาขอบสีขาว
                // side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 2),
              ),
              color: Colors.transparent, // เปลี่ยนเป็นโปร่งใส
              elevation: 15, // ปิดเงา
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // ทำมุมโค้งมน
                          borderSide: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), // ทำมุมโค้งมน
                          borderSide: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      obscureText: true, // ซ่อนรหัสผ่าน
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _login, // เรียกฟังก์ชันล็อกอิน
                      child: const Text('Login', style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 0, 0, 0))),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50), // ขนาดปุ่มเต็มความกว้าง
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: const Color.fromARGB(255, 48, 176, 255),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        // ใช้ Navigator เพื่อไปยังหน้า RegisterPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        'Don\'t have an account? Sign up here.',
                        style: TextStyle(color: Color.fromARGB(255, 254, 254, 254)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
