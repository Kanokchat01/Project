import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class ChatPage extends StatefulWidget {
  final int currentUserId;
  final int otherUserId;
  final String otherUsername;

  const ChatPage({
    Key? key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUsername,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  bool _isSending = false;
  Timer? _timer; // Timer สำหรับเรียกดึงข้อความใหม่

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // เริ่ม Timer เพื่อดึงข้อความทุก ๆ 2 วินาที
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer t) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel(); // หยุด Timer
    _videoController?.dispose();
    super.dispose();
  }

  // ดึงข้อความและไฟล์จากเซิร์ฟเวอร์
  Future<void> _fetchMessages() async {
    final response = await http.get(Uri.parse(
        'http://192.168.213.1/get_messages.php?currentUserId=${widget.currentUserId}&otherUserId=${widget.otherUserId}'));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      setState(() {
        messages = responseData.map((msg) {
          return {
            'content': msg['message'] ?? '',
            'timestamp': msg['created_at'] ?? '',
            'isImage': msg['media_type'] == 'image',
            'isVideo': msg['media_type'] == 'video',
            'mediaUrl': msg['media_url'] != null ? 'http://192.168.213.1/imag/' + msg['media_url'] : '',
            'videoUrl': msg['video_url'] != null ? 'http://192.168.213.1/imag/' + msg['video_url'] : '',
            'senderId': msg['sender_id'],
          };
        }).toList();
      });
    } else {
      print('Failed to load messages');
    }
  }

  // ฟังก์ชันเลือกมีเดีย (รูปภาพหรือวิดีโอ)
  Future<void> _pickMedia() async {
    final pickedFile = await showDialog<XFile>(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('โปรดเลือก'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('ส่งรูปภาพ หรือ Gif'),
                onTap: () async {
                  final XFile? imageFile = await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.of(context).pop(imageFile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('ส่งวิดีโอ .mp4'),
                onTap: () async {
                  final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);
                  Navigator.of(context).pop(videoFile);
                },
              ),
            ],
          ),
        ),
      );
    });

    if (pickedFile != null) {
      await _sendMessage(mediaFile: pickedFile);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No media selected.')));
    }
  }

  // ฟังก์ชันส่งข้อความหรือไฟล์
  Future<void> _sendMessage({String? messageContent, XFile? mediaFile}) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    String timestamp = DateTime.now().toIso8601String();

    if (mediaFile != null) {
      await _uploadMedia(mediaFile, timestamp);
    } else if (messageContent != null && messageContent.isNotEmpty) {
      await _sendMessageToServer(messageContent, timestamp);
      setState(() {
        messages.add({
          'content': messageContent,
          'timestamp': timestamp,
          'isImage': false,
          'isVideo': false,
          'mediaUrl': '',
          'videoUrl': '',
          'senderId': widget.currentUserId,
        });
      });
      _controller.clear();
    }

    setState(() {
      _isSending = false;
    });
  }

  // ฟังก์ชันส่งข้อความไปยังเซิร์ฟเวอร์
  Future<void> _sendMessageToServer(String content, String timestamp) async {
    final response = await http.post(
      Uri.parse('http://192.168.213.1/save_message.php'),
      body: {
        'content': content,
        'currentUserId': widget.currentUserId.toString(),
        'otherUserId': widget.otherUserId.toString(),
        'createdAt': timestamp,
      },
    );

    if (response.statusCode != 200) {
      print('Failed to send message: ${response.body}');
    }
  }

  // อัปโหลดไฟล์สื่อไปยังเซิร์ฟเวอร์
  Future<void> _uploadMedia(XFile mediaFile, String timestamp) async {
    var request = http.MultipartRequest('POST', Uri.parse('http://192.168.213.1/upload_media.php'));
    request.files.add(await http.MultipartFile.fromPath('media', mediaFile.path));
    request.fields['currentUserId'] = widget.currentUserId.toString();
    request.fields['otherUserId'] = widget.otherUserId.toString();
    request.fields['createdAt'] = timestamp;

    final response = await request.send();
    if (response.statusCode == 200) {
      String mediaType = mediaFile.path.endsWith(".mp4") ? 'video' : 'image';
      final mediaUrl = mediaFile.path.split('/').last;

      // อัปเดตรายการ messages ทันที
      setState(() {
        messages.add({
          'content': '',
          'timestamp': timestamp,
          'isImage': mediaType == 'image',
          'isVideo': mediaType == 'video',
          'mediaUrl': mediaType == 'image' ? 'http://192.168.213.1/imag/' + mediaUrl : '',
          'videoUrl': mediaType == 'video' ? 'http://192.168.213.1/imag/' + mediaUrl : '',
          'senderId': widget.currentUserId,
        });
      });
    } else {
      print('Failed to upload media: ${response.reasonPhrase}');
    }
  }

  // แสดงผลข้อความหรือสื่อ
  Widget _buildMessageContent(Map<String, dynamic> message) {
    final isImage = message['isImage'] ?? false;
    final isVideo = message['isVideo'] ?? false;
    final mediaUrl = message['mediaUrl'] ?? '';
    final videoUrl = message['videoUrl'] ?? '';

    if (mediaUrl.isEmpty && videoUrl.isEmpty) {
      return Text(
        message['content'],
        style: TextStyle(fontSize: 16, color: Colors.black87),
      );
    }

    if (isImage) {
      return Image.network(
        mediaUrl,
        errorBuilder: (context, error, stackTrace) {
          return const Text('Failed to load image');
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          } else {
            return const CircularProgressIndicator();
          }
        },
        height: 150,
        fit: BoxFit.cover,
      );
    } else if (isVideo) {
      return _buildVideoPlayer(videoUrl);
    } else {
      return Text(
        message['content'],
        style: TextStyle(fontSize: 16, color: Colors.black87),
      );
    }
  }

  // สร้าง Video Player สำหรับแสดงผลวิดีโอจาก URL
  Widget _buildVideoPlayer(String videoUrl) {
    if (_videoController?.dataSource != videoUrl) {
      _videoController?.dispose(); // ปล่อยวิดีโอเก่า
      _videoController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            _videoController!.play(); // เล่นวิดีโอโดยอัตโนมัติ
          });
        }).catchError((error) {
          print('Video player error: $error'); // พิมพ์ข้อผิดพลาดถ้ามี
        });
    }
    return _videoController!.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )
        : const CircularProgressIndicator();
  }

  // จัดการเวลาแสดงผล
  String formatTimestamp(String timestamp) {
    try {
      var dateTime = DateTime.parse(timestamp);
      return DateFormat.yMMMd().add_jm().format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.otherUsername}',style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color.fromARGB(255, 34, 34, 161),
        iconTheme: const IconThemeData(color: Colors.white)
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg3.png'), // เปลี่ยนเป็น path ของภาพที่ต้องการใช้
            fit: BoxFit.cover, // ปรับให้เต็มพื้นที่
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message['senderId'] == widget.currentUserId;

                  return Align(
                    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isCurrentUser ? const Color.fromRGBO(150, 222, 255, 1) : const Color.fromARGB(255, 141, 166, 255),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          _buildMessageContent(message),
                          const SizedBox(height: 5),
                          Text(
                            formatTimestamp(message['timestamp']),
                            style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.collections),
                    onPressed: _pickMedia,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter message',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendMessage(messageContent: _controller.text),
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
