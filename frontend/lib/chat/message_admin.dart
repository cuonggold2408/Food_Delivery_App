// messenger_admin.dart
import 'package:flutter/material.dart';
import 'package:frontend/chat/messenger_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MessageAdminScreen(),
    );
  }
}

class MessageAdminScreen extends StatefulWidget {
  const MessageAdminScreen({super.key});

  @override
  _MessageAdminScreenState createState() => _MessageAdminScreenState();
}

class _MessageAdminScreenState extends State<MessageAdminScreen> {
  String? _authToken;
  List<dynamic> _chats = [];
  bool _isLoading = true;
  final int _adminId = 1; // Placeholder: Replace with actual admin ID from auth

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchMessages();
  }

  Future<void> _loadTokenAndFetchMessages() async {
    await _loadToken();
    await _fetchMessages();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('access_token');
    });
    print('Loaded token: $_authToken');
  }

  Future<void> _fetchMessages() async {
    if (_authToken == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://api.df.nguyenquangcuong.pro/chat/admin/list?page=1&limit=10&status=pending',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response: $data');
        setState(() {
          _chats = data['data']['chats'] ?? [];
          _isLoading = false;
        });
      } else {
        print('Failed to load chats: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching chats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back),
        title: const Text('Messages'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Messages (${_chats.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Container(padding: const EdgeInsets.all(2)),
              ],
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chats.isEmpty
              ? const Center(child: Text('No messages available'))
              : ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  final userName = chat['user']?['name'] ?? 'Unknown User';
                  final userId = chat['user']?['user_id'] ?? 0;
                  final chatId = chat['chat_id'] ?? 0;

                  final messages =
                      chat['messages'] != null
                          ? List.from(chat['messages'])
                          : [];
                  messages.sort(
                    (a, b) => DateTime.parse(
                      b['created_at'],
                    ).compareTo(DateTime.parse(a['created_at'])),
                  );

                  final lastMessage =
                      messages.isNotEmpty
                          ? messages[0]['content'] ?? 'No message'
                          : 'No message';
                  final lastMessageTime =
                      chat['last_message_at'] != null
                          ? _formatDateTime(chat['last_message_at'])
                          : 'Unknown time';
                  final unreadCount =
                      messages
                          .where(
                            (msg) =>
                                msg['is_read'] == false &&
                                msg['sender_type'] == 'user',
                          )
                          .length;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lastMessageTime,
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatDetailScreen(
                                  userId: userId,
                                  chatId: chatId,
                                  adminId: _adminId,
                                  accessToken: _authToken ?? '',
                                  role: 'admin', // Pass role as 'admin'
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.grid_view), onPressed: () {}),
            IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.orange,
              mini: true,
              child: const Icon(Icons.add),
            ),
            IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime).toLocal();
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown time';
    }
  }
}
