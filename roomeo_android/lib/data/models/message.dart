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
    return Message(
      messageId: json['message_id'],
      roomId: json['room_id'],
      userId: json['user_id'],
      username: json['username'],
      content: json['content'],
      messageType: json['message_type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
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
