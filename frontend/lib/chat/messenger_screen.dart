import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/socket_service.dart';
import 'package:socket_io_client/socket_io_client.dart';

class ChatDetailScreen extends StatefulWidget {
  final int userId;
  final int chatId;
  final int adminId;
  final String accessToken;
  final String role;

  const ChatDetailScreen({
    super.key,
    required this.userId,
    required this.chatId,
    required this.adminId,
    required this.accessToken,
    required this.role,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _controller = TextEditingController();
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
    final socketUserId =
        widget.role == 'admin' ? widget.adminId : widget.userId;
    _socketService.connect(socketUserId, widget.accessToken);
    _socketService.joinChat(widget.chatId);

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

    _socketService.onMessageReceived((data) {
      if (!_messages.any((msg) => msg['message_id'] == data['message_id'])) {
        print('Received message: $data');
        setState(() {
          _messages.insert(0, data);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        });
      }
    });

    _socketService.socket.on('typing', (data) {
      if (data is Map<String, dynamic> &&
          data['user_id'] !=
              (widget.role == 'admin' ? widget.adminId : widget.userId)) {
        setState(() {
          _typingUser = data['is_typing'] ? 'Đang nhập...' : null;
        });
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.df.nguyenquangcuong.pro/chat/${widget.chatId}/messages',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );

      print('Fetch Messages API Status: ${response.statusCode}');
      print('Fetch Messages API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = List<Map<String, dynamic>>.from(
          data['data']['messages'],
        );
        print('Parsed messages: $messages');
        setState(() {
          _messages.clear();
          _messages.addAll(
            messages.reversed
                .map(
                  (msg) => {
                    'message_id': msg['message_id'],
                    'chat_id': msg['chat_id'],
                    'sender_id': msg['sender_id'],
                    'sender_type': msg['sender_type'],
                    'message_type': msg['message_type'],
                    'content': msg['content'],
                    'timestamp': msg['created_at'],
                  },
                )
                .toList(),
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            0,
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
    if (_controller.text.isEmpty) return;

    final messageData = {
      'chat_id': widget.chatId,
      'content': _controller.text,
      'message_type': 'text',
      'sender_id': widget.role == 'admin' ? widget.adminId : widget.userId,
      'sender_type': widget.role,
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
          'chat_id': widget.chatId,
          'content': _controller.text,
          'message_type': 'text',
        }),
      );

      if (response.statusCode == 201) {
        print('Message sent successfully: $messageData');
        final messageId = jsonDecode(response.body)['data']['message_id'];
        setState(() {
          _messages.insert(0, {...messageData, 'message_id': messageId});
          _controller.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        });
        _socketService.sendMessage({...messageData, 'message_id': messageId});
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
    _controller.dispose();
    _scrollController.dispose();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.role == 'admin'
              ? 'Chat with User ${widget.userId}'
              : 'Chat with Admin ${widget.adminId}',
        ),
        actions: [
          Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
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
                final isMe =
                    widget.role == 'admin'
                        ? message['sender_id'] == 1
                        : message['sender_type'] == 'user';
                print(
                  'Message: $message, isMe: $isMe, role: ${widget.role}, sender_type: ${message['sender_type']}, sender_id: ${message['sender_id']}, adminId: ${widget.adminId}, userId: ${widget.userId}',
                );
                return _buildMessageBubble(message, isMe);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0).copyWith(
            topLeft:
                isMe ? const Radius.circular(12) : const Radius.circular(0),
            topRight:
                isMe ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message['content'],
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
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) {
                _socketService.emitTyping(
                  widget.chatId,
                  widget.role == 'admin' ? widget.adminId : widget.userId,
                  val.isNotEmpty,
                );
              },
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
