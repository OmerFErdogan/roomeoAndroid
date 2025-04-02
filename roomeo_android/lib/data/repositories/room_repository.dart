import 'package:dio/dio.dart';
import '../models/room.dart';
import '../models/room_participant.dart';
import '../../core/init/network_manager.dart';
import '../../core/error/exceptions.dart';

class RoomRepository {
  final _dio = NetworkManager.instance.dio;

  // Kullanıcının odalarını getir
  // Kullanıcının odalarını getir (güncellenmiş versiyon)
  Future<List<Room>> getUserRooms() async {
    try {
      final response = await _dio.get('/rooms/user');

      if (response.data['rooms'] == null) {
        return [];
      }

      final List<Room> rooms = [];
      for (var roomData in response.data['rooms']) {
        final room = Room.fromJson(roomData);

        // Her oda için aktif katılımcıları al
        final participants = await getActiveParticipants(room.roomId);

        // Odayı güncellenmiş katılımcı bilgileriyle ekle
        rooms.add(room.copyWith(
            currentParticipants: participants.length,
            participants: participants,
            maxParticipants: room.roomType == 'premium' ? 18 : 6,
            roomType: room.roomType.isEmpty ? 'normal' : room.roomType));
      }

      return rooms;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized access');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to fetch rooms');
    }
  }

  // Oda detaylarını getir
  Future<Room> getRoomDetails(int roomId) async {
    try {
      final response = await _dio.get('/rooms/$roomId');

      // Aktif katılımcıları da al
      final participants = await getActiveParticipants(roomId);

      final room = Room.fromJson(response.data);

      // Katılımcı sayısını güncelle
      return room.copyWith(
          currentParticipants: participants.length,
          participants: participants,
          maxParticipants: room.roomType == 'premium' ? 18 : 6);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to get room details');
    }
  }

  // Aktif katılımcıları getir
  Future<List<RoomParticipant>> getActiveParticipants(int roomId) async {
    try {
      final response = await _dio.get('/rooms/$roomId/active-participants');

      if (response.data == null) {
        return [];
      }

      return (response.data as List)
          .map((json) => RoomParticipant.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('Error getting active participants: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      return []; // Hata durumunda boş liste dön
    }
  }

  // Odaya giriş yap (Enter)
  Future<void> enterRoom(int roomId) async {
    try {
      await _dio.post('/rooms/$roomId/enter');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ConflictException('Already active in another room');
      } else if (e.response?.statusCode == 403) {
        throw ForbiddenException('Not allowed to enter this room');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to enter room');
    }
  }

  // Odadan çıkış yap (Exit)
  Future<void> exitRoom(int roomId) async {
    try {
      await _dio.post('/rooms/$roomId/exit');
    } on DioException catch (e) {
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to exit room');
    }
  }

  // Odaya katıl (Join - Membership)

  Future<void> joinRoom(int roomId, {String? accessCode}) async {
    try {
      // Request body'yi doğru formatta oluştur
      final Map<String, dynamic> data = accessCode != null &&
              accessCode.isNotEmpty
          ? {'access_code': accessCode.trim()} // trim() ile boşlukları temizle
          : {};

      final response = await _dio.post(
        '/rooms/$roomId/join',
        data: data, // data parametresini kullan
      );

      if (response.statusCode != 200) {
        throw NetworkException(
            response.data?['error'] ?? 'Failed to join room');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ConflictException('Already a member of this room');
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data?['error'] ?? 'Failed to join room';
        if (errorMessage.contains('access code')) {
          throw ValidationException('Invalid access code');
        }
        throw ValidationException(errorMessage);
      } else if (e.response?.statusCode == 403) {
        throw ForbiddenException('Not allowed to join this room');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to join room');
    }
  }

  // Odadan ayrıl (Leave - Membership)
  Future<void> leaveRoom(int roomId) async {
    try {
      await _dio.post('/rooms/$roomId/leave');
    } on DioException catch (e) {
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to leave room');
    }
  }

  // Yeni oda oluştur

  Future<Room> createRoom({
    required String name,
    required String description,
    required String roomType,
    required bool isPrivate,
  }) async {
    try {
      print('Creating room with params:'); // Debug log
      print('Name: $name');
      print('Description: $description');
      print('Room Type: $roomType');
      print('Is Private: $isPrivate');

      final response = await _dio.post('/rooms', data: {
        'name': name,
        'description': description,
        'room_type': roomType.isEmpty ? 'normal' : roomType,
        'is_private': isPrivate,
        'settings': {
          'allow_guest_users': false,
          'require_approval': isPrivate,
          'enable_chat_history': true,
        },
        'max_participants': roomType == 'premium' ? 18 : 6
      });

      print('Create room response: ${response.data}'); // Debug log

      if (response.statusCode == 201) {
        final createdRoom = Room.fromJson(response.data);
        return createdRoom;
      }

      throw NetworkException('Failed to create room');
    } on DioException catch (e) {
      print('Create room error: ${e.response?.data}'); // Debug log
      print('Error status code: ${e.response?.statusCode}');

      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized access');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to create room');
    }
  }

  // Oda bilgilerini güncelle
  Future<Room> updateRoom({
    required int roomId,
    String? name,
    String? description,
    bool? isPrivate,
    String? accessCode,
  }) async {
    try {
      final data = {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isPrivate != null) 'is_private': isPrivate,
        if (accessCode != null) 'access_code': accessCode,
      };

      final response = await _dio.put('/rooms/$roomId', data: data);
      return Room.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to update room');
    }
  }

  // Oda tipini güncelle (normal/premium)
  Future<void> updateRoomType(int roomId, String roomType) async {
    try {
      await _dio.put('/rooms/$roomId/type', data: {'room_type': roomType});
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw ForbiddenException('Not authorized to change room type');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to update room type');
    }
  }

  // Odayı sil
  Future<void> deleteRoom(int roomId) async {
    try {
      await _dio.delete('/rooms/$roomId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to delete room');
    }
  }

  // Oda istatistiklerini getir
  Future<Map<String, dynamic>> getRoomStats(int roomId) async {
    try {
      final response = await _dio.get('/rooms/$roomId/stats');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to get room statistics');
    }
  }

  // Odanın yoğun saatlerini getir
  Future<List<Map<String, dynamic>>> getRoomPeakHours(int roomId) async {
    try {
      final response = await _dio.get('/rooms/$roomId/stats/peak-hours');
      return List<Map<String, dynamic>>.from(response.data['peak_hours']);
    } on DioException catch (e) {
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to get peak hours');
    }
  }

  // RoomRepository sınıfına eklenecek yeni metod
  // RoomRepository sınıfına eklenecek güncelleme
  Future<List<Room>> searchRooms(String query) async {
    try {
      final response = await _dio.get('/rooms', queryParameters: {
        'query': query,
      });

      // API response doğrudan array dönüyor
      if (response.data == null) {
        return [];
      }

      // Response bir array olduğu için doğrudan map edebiliriz
      final List<dynamic> roomsData = response.data;
      final rooms = roomsData.map((json) => Room.fromJson(json)).toList();

      // Her oda için güncel katılımcı sayısını ayarla
      for (var room in rooms) {
        final participants = room.participants ?? [];
        room = room.copyWith(
            currentParticipants: participants.length,
            maxParticipants: room.roomType == 'premium' ? 18 : 6);
      }

      return rooms;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized access');
      }
      throw NetworkException(
        e.response?.data?['error'] ?? 'Failed to search rooms',
      );
    }
  }

  // Odanın haftalık trendlerini getir
  Future<List<Map<String, dynamic>>> getRoomWeeklyTrends(int roomId) async {
    try {
      final response = await _dio.get('/rooms/$roomId/stats/weekly-trends');
      return List<Map<String, dynamic>>.from(response.data['weekly_trends']);
    } on DioException catch (e) {
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to get weekly trends');
    }
  }

  // Oda katılımcılarının aktiflik durumunu zorla güncelle
  Future<void> refreshRoomParticipants(int roomId) async {
    try {
      await _dio.post('/rooms/$roomId/refresh-participants');
      print('Sent refresh participants request for room $roomId');
    } on DioException catch (e) {
      print('Error refreshing participants: ${e.response?.data}');
      throw NetworkException(
          e.response?.data?['error'] ?? 'Failed to refresh participants');
    }
  }
}
