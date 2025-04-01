// room_participant.dart
class RoomParticipant {
  final int id; // API'de 'participant_id' yerine 'id' kullanılıyor
  final int roomId;
  final int userId;
  final String username;
  final DateTime lastSeenAt;
  final String role;
  final bool isBanned;
  final bool isActive;

  RoomParticipant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.lastSeenAt,
    required this.role,
    required this.isBanned,
    required this.isActive,
  });

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      id: json['id'],
      roomId: json['room_id'],
      userId: json['user_id'],
      username: json['username'],
      lastSeenAt: DateTime.parse(json['last_seen_at']),
      role: json['role'],
      isBanned: json['is_banned'],
      isActive: json['is_active'],
    );
  }
}
