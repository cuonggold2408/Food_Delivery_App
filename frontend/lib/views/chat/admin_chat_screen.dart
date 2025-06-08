import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart';

class AdminChatScreen extends StatefulWidget {
  final int userId;
  final int adminChatId;
  final String accessToken;

  const AdminChatScreen({
    super.key,
    required this.userId,
    required this.adminChatId,
    required this.accessToken,
  });

  @override
  _AdminChatScreenState createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SocketService _socketService = SocketService();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  String? _typingUser;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _setupSocket();
  }

  void _setupSocket() {
    _socketService.connect(widget.userId, widget.accessToken);
    _socketService.joinChat(widget.adminChatId);

    // Handle socket connection status
    _socketService.socket.onConnect((_) {
      setState(() => _isConnected = true);
      print('Connected to Socket.IO');
    });

    _socketService.socket.onDisconnect((_) {
      setState(() => _isConnected = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mất kết nối với server')));
    });

    _socketService.socket.onConnectError((data) {
      print('Connection error: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể kết nối với server')),
      );
    });

    // Handle incoming messages
    _socketService.onMessageReceived((data) {
      if (!_messages.any((msg) => msg['message_id'] == data['message_id'])) {
        setState(() {
          _messages.add(data);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        });
      }
    });

    // Handle typing events
    _socketService.socket.on('typing', (data) {
      if (data is Map<String, dynamic> && data['user_id'] != widget.userId) {
        setState(() {
          _typingUser = data['is_typing'] ? 'Đang nhập...' : null;
        });
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
        body: jsonEncode({
          'subject': 'Fetch Messages',
          'initial_message': 'Requesting chat history',
        }),
      );

      print('Fetch Messages API Status: ${response.statusCode}');
      print('Fetch Messages API Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final messages = List<Map<String, dynamic>>.from(
          data['data']['messages'],
        );
        setState(() {
          _messages.clear();
          _messages.addAll(
            messages.map(
              (msg) => {
                'message_id': msg['message_id'],
                'chat_id': msg['chat_id'],
                'sender_id': msg['sender_id'],
                'sender_type': msg['sender_type'],
                'message_type': msg['message_type'],
                'content': msg['content'],
                'timestamp': msg['created_at'],
              },
            ),
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể tải tin nhắn')));
      }
    } catch (e) {
      print('Error fetching messages: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải tin nhắn: $e')));
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageData = {
      'chat_id': widget.adminChatId,
      'content': _messageController.text,
      'message_type': 'text',
      'sender_id': widget.userId,
      'sender_type': 'admin',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.df.nguyenquangcuong.pro/chat/message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
        body: jsonEncode({
          'chat_id': widget.adminChatId,
          'content': _messageController.text,
          'message_type': 'text',
        }),
      );

      if (response.statusCode == 201) {
        print('Message sent successfully');
        setState(() {
          _messages.add({
            ...messageData,
            'message_id': jsonDecode(response.body)['data']['message_id'],
          });
          _messageController.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        });
        _socketService.sendMessage({
          ...messageData,
          'message_id': jsonDecode(response.body)['data']['message_id'],
        });
      } else {
        print('Failed to send message: ${response.body}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể gửi tin nhắn')));
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi khi gửi tin nhắn')));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat #${widget.adminChatId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Icon(_isConnected ? Icons.wifi : Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length + (_typingUser != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_typingUser != null && index == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _typingUser!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    );
                  }
                  final message = _messages[index];
                  final isMe = message['sender_id'] == widget.userId;
                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isMe
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['content'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _formatTimestamp(message['timestamp']),
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.grey,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (val) {
                      _socketService.emitTyping(
                        widget.adminChatId,
                        widget.userId,
                        val.isNotEmpty,
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
