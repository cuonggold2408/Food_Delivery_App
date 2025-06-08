// lib/models/message_model.dart
class Message {
  final int senderId;
  final String content;
  final String createdAt;

  Message({
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: json['created_at'],
    );
  }
}
