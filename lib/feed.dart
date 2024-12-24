import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'PostWidget.dart';
import 'new_post_page.dart';
import 'UsersListPage.dart';
import 'EditProfilePage.dart';
import 'login.dart';

class FeedPage extends StatefulWidget {
  final int userId;

  const FeedPage({super.key, required this.userId});

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Map<String, dynamic>> posts = [];
  String _username = "Loading...";
  String? _profileImageUrl;
  late int _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _fetchPosts();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.213.1/get_user_profile.php?userId=$_userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _username = data['username'] ?? 'Unknown User';
          _profileImageUrl = data['profile_image'] != null
              ? 'http://192.168.213.1/${data['profile_image']}'
              : null;
        });
      } else {
        debugPrint('Failed to load profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.213.1/fetch_posts.php'));
      if (response.statusCode == 200) {
        setState(() {
          posts = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        debugPrint('Failed to load posts');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _addNewPost(String content, dynamic image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://192.168.213.1/upload_post.php'));
      request.fields['content'] = content;

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        await _fetchPosts();
      } else {
        debugPrint('Failed to add post');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg3.png'), // เปลี่ยนเป็น path ของภาพที่ต้องการใช้
            fit: BoxFit.cover, // ปรับให้เต็มพื้นที่
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NewPostPage(onPostCreated: _addNewPost)),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Create New Post', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 14, 23, 64), // ปรับสีปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // มุมโค้งมน
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // เพิ่มพื้นที่ภายในปุ่ม
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: posts.isEmpty
                  ? Center(
                      child: const Text(
                        'No posts available',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // เพิ่ม margin
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // ทำมุมการ์ดโค้งมน
                          ),
                          child: PostWidget(
                            username: posts[index]['username'] ?? '',
                            content: posts[index]['content'] ?? '',
                            imageUrl: posts[index]['image_url'] != null
                                ? 'http://192.168.213.1/${posts[index]['image_url']}'
                                : null,
                            createdAt: posts[index]['created_at'] ?? 'Unknown Date',
                            likes: posts[index]['likes'] ?? 0,
                            comments: posts[index]['comments'] ?? 0,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 34, 34, 161), // สี AppBar
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white), // เงาเล็กน้อย
        title: Text(
          'Instamaigram',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), // ขนาดฟอนต์ใหญ่ขึ้น
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage(userId: _userId)),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!) as ImageProvider<Object>
                      : const AssetImage('assets/Profile.png'),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), // ขนาดฟอนต์
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat,color: Color.fromARGB(255, 0, 0, 0)),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout,color: Color.fromARGB(255, 0, 0, 0)),
            label: 'Logout',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UsersListPage(
                  loggedInUserId: _userId,
                  loggedInUsername: _username,
                ),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        },
      ),
    );
  }
}
