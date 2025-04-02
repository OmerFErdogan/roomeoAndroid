// Extend your Message class in lib/data/models/message.dart

class Message {
  final int messageId;
  final int roomId;
  final int userId;
  final String username;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? clientId; // Add this field to support client ID tracking

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
    this.clientId, // Added optional client ID
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        messageId: json['message_id'] ?? -1,
        roomId: json['room_id'] ?? -1,
        userId: json['user_id'] ?? -1,
        username: json['username'] ?? 'Anonim',
        content: json['content'] ?? '',
        messageType: json['message_type'] ?? 'text',
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(
            json['updated_at'] ?? DateTime.now().toIso8601String()),
        isDeleted: json['is_deleted'] ?? false,
        clientId: json['client_id'], // Extract client ID if present
      );
    } catch (e) {
      print('Message parsing error: $e');
      print('Raw JSON: $json');
      // Return default message on error
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
      'client_id': clientId, // Include client ID in JSON
    };
  }

  // System message factory constructor
  factory Message.system({
    required int roomId,
    required String content,
    required int userId,
    required String username,
  }) {
    final now = DateTime.now();
    return Message(
      messageId: -1,
      roomId: roomId,
      userId: userId,
      username: username,
      content: content,
      messageType: 'system',
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create a copy with optional parameter updates
  Message copyWith({
    int? messageId,
    int? roomId,
    int? userId,
    String? username,
    String? content,
    String? messageType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? clientId,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      clientId: clientId ?? this.clientId,
    );
  }
}
