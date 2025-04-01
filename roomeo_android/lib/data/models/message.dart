// lib/data/models/message.dart
class Message {
  final int messageId;
  final int roomId;
  final int userId;
  final String username; // API'den doğrudan geliyor
  final String content;
  final String messageType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Message({
    required this.messageId,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.content,
    required this.messageType,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        messageId: json['message_id'] ?? -1, // Null güvenli
        roomId: json['room_id'] ?? -1, // Null güvenli
        userId: json['user_id'] ?? -1, // Null güvenli
        username: json['username'] ?? 'Anonim',
        content: json['content'] ?? '',
        messageType: json['message_type'] ?? 'text',
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(
            json['updated_at'] ?? DateTime.now().toIso8601String()),
        isDeleted: json['is_deleted'] ?? false,
      );
    } catch (e) {
      print('Message parsing error: $e');
      print('Raw JSON: $json');
      // Hata durumunda varsayılan bir mesaj döndür
      return Message(
        messageId: -1,
        roomId: -1,
        userId: -1,
        username: 'Hata',
        content: 'Mesaj gösterilemedi',
        messageType: 'error',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'room_id': roomId,
      'user_id': userId,
      'username': username,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  // System mesajları için factory constructor
  factory Message.system({
    required int roomId,
    required String content,
    required int userId,
    required String username,
  }) {
    final now = DateTime.now();
    return Message(
      messageId: -1, // System mesajları için özel ID
      roomId: roomId,
      userId: userId,
      username: username,
      content: content,
      messageType: 'system',
      createdAt: now,
      updatedAt: now,
    );
  }
}
