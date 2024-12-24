import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ChatPage.dart'; // เพิ่มหน้าแชท

class UsersListPage extends StatefulWidget {
  final int loggedInUserId;
  final String loggedInUsername;

  const UsersListPage({super.key, required this.loggedInUserId, required this.loggedInUsername});

  @override
  _UsersListPageState createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // ฟังก์ชันดึงข้อมูลผู้ใช้จากฐานข้อมูล
  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.213.1/get_all_users.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = List<Map<String, dynamic>>.from(data)
              .where((user) => user['id'] != widget.loggedInUserId && user['id'] != null)
              .toList();
        });
      } else {
        print('Failed to load users');
      }
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users List', style: TextStyle(color: Colors.white)), // เปลี่ยนสีหัวข้อ
        backgroundColor: const Color.fromARGB(255, 34, 34, 161), // เปลี่ยนสี AppBar
        elevation: 4, // เพิ่มเงา
        iconTheme: const IconThemeData(color: Colors.white), // เปลี่ยนสีไอคอนใน AppBar เป็นสีขาว
      ),
      body: Container(
        color: Colors.grey[100], // พื้นหลังที่สว่างขึ้น
        child: users.isEmpty
            ? const Center(child: CircularProgressIndicator()) // กำลังโหลด
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userId = user['id'] ?? 0;
                  final userName = user['username'] ?? 'Unknown User';
                  final profileImage = user['profile_image'] != null
                      ? NetworkImage('http://192.168.213.1/' + user['profile_image'])
                      : const AssetImage('assets/Profile.png') as ImageProvider<Object>;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // ระยะห่างการ์ด
                    elevation: 6, // เพิ่มความลึกให้กับการ์ด
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // มุมการ์ดโค้งมน
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileImage,
                        radius: 30, // ขนาดของ Avatar
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), // ขนาดฟอนต์
                      ),
                      subtitle: Text(
                        'Tap to chat',
                        style: TextStyle(color: Colors.grey[600]), // เปลี่ยนสีข้อความรอง
                      ),
                      onTap: () {
                        if (userId != 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                currentUserId: widget.loggedInUserId,
                                otherUserId: userId,
                                otherUsername: userName,
                              ),
                            ),
                          );
                        } else {
                          print('User ID is invalid');
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
