import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  final String username;

  const UserProfilePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
      ),
      body: Center(
        child: Text('Profile of $username'), // แสดงรายละเอียดเพิ่มเติมที่นี่
      ),
    );
  }
}
