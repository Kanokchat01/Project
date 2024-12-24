import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final int userId;

  const EditProfilePage({super.key, required this.userId});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); 
  File? _profileImage;
  String _username = "";
  String _email = ""; 
  String? _profileImageUrl;
  List<dynamic> _userPosts = []; 
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchUserPosts(); 
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.213.1/get_user_profile.php?userId=${widget.userId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _username = data['username'] ?? 'Unknown User';
          _email = data['email'] ?? ''; 
          _profileImageUrl = data['profile_image'] != null
              ? 'http://192.168.213.1/' + data['profile_image']
              : null;
          _usernameController.text = _username;
          _emailController.text = _email; 
        });
      } else {
        print('Failed to load profile');
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.213.1/get_user_posts.php?userId=${widget.userId}'));
      if (response.statusCode == 200) {
        setState(() {
          _userPosts = json.decode(response.body); 
        });
      } else {
        print('Failed to load posts');
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.213.1/update_user_profile.php'));
    request.fields['userId'] = widget.userId.toString();
    request.fields['username'] = _usernameController.text;
    request.fields['email'] = _emailController.text; 

    if (_profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _profileImage!.path));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      print('Profile updated');
      setState(() {
        _profileImageUrl = 'http://192.168.213.1/' + _profileImage!.path.split('/').last; // Update the profile image URL
      });
      Navigator.pop(context);
    } else {
      print('Failed to update profile');
    }
  }

  Future<void> _deletePost(int postId) async {
    final response = await http.delete(Uri.parse('http://192.168.213.1/delete_post.php?postId=$postId'));
    
    if (response.statusCode == 200) {
      setState(() {
        _userPosts.removeWhere((post) => post['id'] == postId); 
      });
      print('Post deleted successfully');
    } else {
      print('Failed to delete post');
    }
  }

  void _editPost(int postId, String currentContent) {
    final TextEditingController editController = TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Enter new content'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (editController.text.isNotEmpty) {
                  final response = await http.post(
                    Uri.parse('http://192.168.213.1/update_post.php'),
                    body: {
                      'postId': postId.toString(),
                      'content': editController.text,
                    },
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      final index = _userPosts.indexWhere((post) => post['id'] == postId);
                      if (index != -1) {
                        _userPosts[index]['content'] = editController.text;
                      }
                    });
                    Navigator.pop(context); 
                  } else {
                    print('Failed to update post');
                  }
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขโปรโฟล์', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color.fromARGB(255, 34, 34, 161),
        iconTheme: const IconThemeData(color: Colors.white) // เปลี่ยนสี AppBar
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage('assets/Profile.png')) as ImageProvider<Object>,
                            radius: 50,
                          ),
                        ),
                        const SizedBox(width: 10), // ระยะห่างระหว่างไอคอนและรูปภาพ
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.camera_alt, color: Color.fromARGB(255, 28, 62, 255)), // ไอคอนกล้อง
                            const SizedBox(height: 5),
                            const Text('เเก้ไขรูปโปรไฟล์', style: TextStyle(color: Color.fromARGB(255, 28, 62, 255))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController, 
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress, 
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('บันทึกการแก้ไข', style: TextStyle(color: Color.fromARGB(255, 28, 62, 255))),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 10),
                    ListView.builder(
                      itemCount: _userPosts.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this list
                      itemBuilder: (context, index) {
                        final post = _userPosts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(post['content'] ?? 'No content'), // Display post content
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _editPost(post['id'], post['content']); // Call edit function
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deletePost(post['id']); // Call delete function
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
