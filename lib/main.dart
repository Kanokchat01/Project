import 'package:flutter/material.dart';
import 'login.dart'; // นำเข้าหน้าล็อกอิน

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Member System',
      debugShowCheckedModeBanner: false, // ปิดแถบ DEBUG
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // เรียกหน้าล็อกอิน
    );
  }
}
