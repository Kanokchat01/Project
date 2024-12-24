import 'package:flutter/material.dart';

class PostWidget extends StatelessWidget {
  final String username; // เพิ่ม username
  final String content;
  final String? imageUrl;
  final String createdAt;
  final int likes;
  final int comments;

  const PostWidget({
    Key? key,
    required this.username,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.likes,
    required this.comments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null)
          Image.network(imageUrl!),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('โพสต์เมื่อ: $createdAt',),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(content),
        ),
      ],
    );
  }
}
