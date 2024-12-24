import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _username = "Loading...";
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Function to load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.213.1/get_user_profile.php?userId=${widget.userId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _username = data['username'] ?? 'Unknown User';
          _profileImageUrl = data['profile_image'] != null
              ? 'http://192.168.213.1/' + data['profile_image']
              : null;
        });
      } else {
        _showErrorMessage('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorMessage('Error loading profile: $e');
    }
  }

  // Function to show error messages
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!) as ImageProvider<Object>
                  : const AssetImage('assets/default_profile.png'),
              radius: 50,
            ),
            const SizedBox(height: 20),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('User ID: ${widget.userId}'),
            // Optional: Add more user information or actions
          ],
        ),
      ),
    );
  }
}
