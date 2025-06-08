import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  Function(Map<String, dynamic>)? _messageCallback;

  void connect(int userId, String accessToken) {
    socket = IO.io(
      'https://api.df.nguyenquangcuong.pro/chat-realtime',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'userId': userId.toString()})
          .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
          .build(),
    );

    socket.onConnect((_) => print('Connected to Socket.IO'));
    socket.onDisconnect((_) => print('Disconnected'));

    // Listen for new messages
    socket.on('message', (data) {
      print('Received new message: $data');
      if (_messageCallback != null && data is Map<String, dynamic>) {
        _messageCallback!(data);
      }
    });
  }

  void joinChat(int chatId) {
    socket.emit('joinChat', {'chat_id': chatId});
  }

  void sendMessage(Map<String, dynamic> message) {
    socket.emit('sendMessage', message);
  }

  void emitTyping(int chatId, int userId, bool isTyping) {
    socket.emit('typing', {
      'chat_id': chatId,
      'user_id': userId,
      'is_typing': isTyping,
    });
  }

  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _messageCallback = callback;
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
