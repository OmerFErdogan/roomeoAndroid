// lib/data/models/room.dart
import 'room_participant.dart';

class Room {
  final int roomId;
  final String name;
  final String description;
  final String roomType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int maxParticipants;
  final bool isPrivate;
  final int createdBy;
  final String status;
  final String? accessCode;
  final List<RoomParticipant>? participants;
  final int currentParticipants;
  final String? role;

  Room({
    required this.roomId,
    required this.name,
    required this.description,
    this.roomType = 'normal',
    required this.createdAt,
    required this.updatedAt,
    this.maxParticipants = 6,
    required this.isPrivate,
    required this.createdBy,
    required this.status,
    this.accessCode = '',
    this.participants,
    this.currentParticipants = 0,
    this.role,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // Debug JSON'ı logla
    print('Room JSON from API: $json');

    // Oda tipi kontrolü
    final roomType = (json['room_type'] as String?)?.isEmpty ?? true
        ? 'normal'
        : json['room_type'];

    // İsimde "private" kelimesi varsa veya is_private true ise private olarak işaretle
    final isPrivate = json['is_private'] == true ||
        (json['name'] as String).toLowerCase().contains('private');

    // Maksimum katılımcı sayısı
    final maxParticipants = roomType == 'premium' ? 18 : 6;

    // Aktif katılımcıları filtrele ve say
    List<RoomParticipant>? participants;
    int currentParticipants = 0;

    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => RoomParticipant.fromJson(p))
          .toList();

      // Sadece aktif ve banlanmamış katılımcıları say
      currentParticipants =
          participants.where((p) => p.isActive && !p.isBanned).length;

      // Aktif katılımcı sayısını loglayalım
      print(
          'Room ${json['room_id']} - Active participants: $currentParticipants');
    } else {
      // Participants yoksa API'den doğrudan current_participants değerini kullanmayı dene
      currentParticipants = json['current_participants'] ?? 0;
      print(
          'Room ${json['room_id']} - Using API participant count: $currentParticipants');
    }

    return Room(
      roomId: json['room_id'],
      name: json['name'],
      description: json['description'],
      roomType: roomType,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      maxParticipants: maxParticipants,
      isPrivate: isPrivate, // Güncellenmiş isPrivate değerini kullan
      createdBy: json['created_by'],
      status: json['status'],
      accessCode: json['access_code'],
      participants: participants,
      currentParticipants: currentParticipants,
      role: json['role'],
    );
  }

  Room copyWith({
    int? roomId,
    String? name,
    String? description,
    String? roomType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maxParticipants,
    bool? isPrivate,
    int? createdBy,
    String? status,
    String? accessCode,
    List<RoomParticipant>? participants,
    int? currentParticipants,
    String? role,
  }) {
    return Room(
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      description: description ?? this.description,
      roomType: roomType ?? this.roomType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isPrivate: isPrivate ?? this.isPrivate,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      accessCode: accessCode ?? this.accessCode,
      participants: participants ?? this.participants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      role: role ?? this.role,
    );
  }

  // Katılımcı sayısını yeniden hesaplar ve günceller
  Room updateParticipantCount() {
    if (participants != null) {
      final count =
          participants!.where((p) => p.isActive && !p.isBanned).length;
      return copyWith(currentParticipants: count);
    }
    return this;
  }

  // Yardımcı getterlar
  String get participantDisplay => "$currentParticipants/$maxParticipants";
  bool get isPremium => roomType == 'premium';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isFull => currentParticipants >= maxParticipants;
  bool get hasActiveParticipants => currentParticipants > 0;
  bool get isActive => status == 'active';

  // Debug için toString metodu
  @override
  String toString() {
    return 'Room(roomId: $roomId, name: $name, participants: $currentParticipants/$maxParticipants, isPrivate: $isPrivate)';
  }

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'name': name,
      'description': description,
      'room_type': roomType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'max_participants': maxParticipants,
      'is_private': isPrivate,
      'created_by': createdBy,
      'status': status,
      'access_code': accessCode,
      'current_participants': currentParticipants,
      'role': role,
    };
  }
}
