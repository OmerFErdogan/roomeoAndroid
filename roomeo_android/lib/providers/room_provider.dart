// lib/providers/room_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Timer için

import '../core/error/exceptions.dart';
import '../data/models/room.dart';
import '../data/models/room_participant.dart';
import '../data/repositories/room_repository.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _repository = RoomRepository();

  List<Room> _userRooms = [];
  Map<int, List<RoomParticipant>> _roomParticipants = {};
  Map<int, WebSocketChannel?> _roomWebSockets = {};
  Map<int, bool> _roomConnectionStatus = {}; // Her oda için bağlantı durumu
  Map<int, Timer?> _pingTimers = {}; // Her oda için ping timer
  bool _isLoading = false;
  String? _error;
  Room? _activeRoom;

  // Getters
  List<Room> get userRooms => _userRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Room? get activeRoom => _activeRoom;

  List<RoomParticipant> getParticipantsForRoom(int roomId) {
    return _roomParticipants[roomId] ?? [];
  }

  bool isRoomConnected(int roomId) {
    return _roomConnectionStatus[roomId] ?? false;
  }

  // Room Operations
  Future<void> fetchUserRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userRooms = await _repository.getUserRooms();
      print('Fetched ${_userRooms.length} rooms for user');

      // Her oda için aktif katılımcıları al
      for (var room in _userRooms) {
        await fetchRoomParticipants(room.roomId);
      }

      _activeRoom = _userRooms.firstWhereOrNull(
        (room) => room.hasActiveParticipants,
      );

      if (_activeRoom != null) {
        print('Active room set: ${_activeRoom!.name} (${_activeRoom!.roomId})');
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching user rooms: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<RoomParticipant>> fetchRoomParticipants(int roomId) async {
    try {
      final participants = await _repository.getActiveParticipants(roomId);
      _roomParticipants[roomId] = participants;
      print('Fetched ${participants.length} participants for room $roomId');

      // Oda bilgisini güncelle
      final index = _userRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        _userRooms[index] = _userRooms[index].copyWith(
          currentParticipants: participants.length,
          participants: participants,
        );

        // Eğer bu aktif odaysa, aktif odayı da güncelle
        if (_activeRoom?.roomId == roomId) {
          _activeRoom = _userRooms[index];
        }
      }

      notifyListeners();
      return participants;
    } catch (e) {
      print('Error fetching participants for room $roomId: $e');
      return [];
    }
  }

  Future<void> enterRoom(int roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Entering room $roomId');
      await _repository.enterRoom(roomId);

      // WebSocket bağlantısını başlat
      await _connectToRoomWebSocket(roomId);

      // Katılımcıları güncelle ve aktif odayı ayarla
      final participants = await fetchRoomParticipants(roomId);
      print(
          'Room $roomId has ${participants.length} participants after entering');

      // Oda bilgilerini güncelle
      final index = _userRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        _activeRoom = _userRooms[index].copyWith(
          currentParticipants: participants.length,
          participants: participants,
        );
        _userRooms[index] = _activeRoom!;
        print(
            'Active room updated: ${_activeRoom!.name} with ${_activeRoom!.currentParticipants} participants');
      } else {
        // Oda bulunamazsa, odayı al ve güncelle
        final room = await _repository.getRoomDetails(roomId);
        _activeRoom = room;
        print(
            'Active room fetched: ${_activeRoom!.name} with ${_activeRoom!.currentParticipants} participants');
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error entering room $roomId: $_error');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> exitRoom(int roomId) async {
    try {
      print('Exiting room $roomId');
      await _repository.exitRoom(roomId);
      _activeRoom = null;

      // WebSocket bağlantısını kapat
      await _disconnectFromRoomWebSocket(roomId);

      // Katılımcı listesini güncelle
      await fetchRoomParticipants(roomId);

      // Tüm kullanıcı odalarını yeniden yükle - güncel durumu almak için
      await fetchUserRooms();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error exiting room $roomId: $_error');
      notifyListeners();
    }
  }

  Future<void> joinRoom(int roomId, {String? accessCode}) async {
    try {
      print(
          'Joining room $roomId, accessCode: ${accessCode != null ? "provided" : "not provided"}');
      await _repository.joinRoom(roomId, accessCode: accessCode);
      await fetchUserRooms();
    } catch (e) {
      _error = e.toString();
      print('Error joining room $roomId: $_error');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveRoom(int roomId) async {
    try {
      print('Leaving room $roomId');
      await _repository.leaveRoom(roomId);
      _userRooms.removeWhere((room) => room.roomId == roomId);
      if (_activeRoom?.roomId == roomId) {
        _activeRoom = null;
      }
      _roomParticipants.remove(roomId);
      await _disconnectFromRoomWebSocket(roomId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error leaving room $roomId: $_error');
      notifyListeners();
      rethrow;
    }
  }

  Future<Room> createRoom({
    required String name,
    required String description,
    required String roomType,
    required bool isPrivate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Creating room: $name, type: $roomType, isPrivate: $isPrivate');
      final room = await _repository.createRoom(
        name: name,
        description: description,
        roomType: roomType,
        isPrivate: isPrivate,
      );

      _userRooms = [..._userRooms, room];
      print('Room created: ${room.name} (${room.roomId})');
      notifyListeners();
      return room;
    } catch (e) {
      _error = e.toString();
      print('Error creating room: $_error');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // WebSocket Operations
  Future<void> _connectToRoomWebSocket(int roomId) async {
    // Halihazırda bağlantı varsa, yeni bağlantı kurma
    if (_roomWebSockets[roomId] != null &&
        _roomConnectionStatus[roomId] == true) {
      print('WebSocket connection already exists for room $roomId');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw AuthException('No token found');
      }

      final wsUrl = Uri.parse(
        'ws://localhost:8081/api/rooms/$roomId/ws?token=$token',
      );

      print('Connecting to WebSocket for room $roomId: $wsUrl');
      final channel = WebSocketChannel.connect(wsUrl);
      _roomWebSockets[roomId] = channel;
      _roomConnectionStatus[roomId] = true;

      // Ping timer'ı başlat
      _pingTimers[roomId] = Timer.periodic(Duration(seconds: 30), (_) {
        if (_roomConnectionStatus[roomId] == true) {
          print('Sending ping to room $roomId');
          channel.sink.add(jsonEncode({'type': 'ping'}));
        }
      });

      // Bağlantı açıldığında katılımcı listesini güncelle
      fetchRoomParticipants(roomId);

      channel.stream.listen(
        (data) {
          print('WebSocket data received for room $roomId: $data');

          if (data is String) {
            if (data.contains('pong')) {
              // Pong yanıtını işle
              _roomConnectionStatus[roomId] = true;
              return;
            }

            // System mesajları için özel işleme
            if (data.contains('joined the room') ||
                data.contains('left the room')) {
              print('Room activity detected: $data');
              // Katılımcı listesini hemen güncelle
              fetchRoomParticipants(roomId);
              // Oda katılımcı sayısını güncelle
              _updateRoomParticipantCount(roomId);
              return;
            }

            try {
              final message = jsonDecode(data);
              _handleWebSocketMessage(roomId, message);
            } catch (e) {
              print('Error processing WebSocket message: $e');
              print('Raw message: $data');
            }
          }
        },
        onError: (error) {
          print('WebSocket Error for room $roomId: $error');
          _roomConnectionStatus[roomId] = false;
          _reconnectWebSocket(roomId);
        },
        onDone: () {
          print('WebSocket connection closed for room $roomId');
          _roomConnectionStatus[roomId] = false;
          _reconnectWebSocket(roomId);
        },
      );

      print('WebSocket connection established for room $roomId');
    } catch (e) {
      print('WebSocket connection error for room $roomId: $e');
      _roomConnectionStatus[roomId] = false;
    }
    notifyListeners();
  }

  Future<void> _disconnectFromRoomWebSocket(int roomId) async {
    print('Disconnecting WebSocket for room $roomId');
    _pingTimers[roomId]?.cancel();
    _pingTimers.remove(roomId);

    final ws = _roomWebSockets[roomId];
    if (ws != null) {
      await ws.sink.close();
      _roomWebSockets.remove(roomId);
    }
    _roomConnectionStatus[roomId] = false;
    notifyListeners();
  }

  void _handleWebSocketMessage(int roomId, dynamic message) {
    print('Processing WebSocket message for room $roomId: $message');

    if (message is String &&
        (message.contains('joined the room') ||
            message.contains('left the room'))) {
      print('User activity detected in room $roomId: $message');
      // Katılımcı listesini ve sayısını hemen güncelle
      fetchRoomParticipants(roomId);
      _updateRoomParticipantCount(roomId);
      return;
    }

    if (message is Map<String, dynamic>) {
      if (message['type'] == 'participants_update') {
        print('Participants update received for room $roomId');
        // Katılımcı listesi güncellemesi
        fetchRoomParticipants(roomId);
        // Katılımcı sayısını güncelle
        _updateRoomParticipantCount(roomId);
      }
    }
  }

  // Yeni eklenen metod - oda katılımcı sayısını günceller
  Future<void> _updateRoomParticipantCount(int roomId) async {
    try {
      print('Updating participant count for room $roomId');
      final participants = await _repository.getActiveParticipants(roomId);

      // Odayı kullanıcının odaları arasında bul
      final index = _userRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        // Oda bulundu, katılımcı sayısını güncelle
        _userRooms[index] = _userRooms[index].copyWith(
          currentParticipants: participants.length,
          participants: participants,
        );

        // Eğer bu aktif odaysa, aktif odayı da güncelle
        if (_activeRoom?.roomId == roomId) {
          _activeRoom = _userRooms[index];
          print(
              'Active room participant count updated: ${_activeRoom!.currentParticipants}');
        }

        notifyListeners();
      }
    } catch (e) {
      print('Error updating room participant count for room $roomId: $e');
    }
  }

  Future<void> _reconnectWebSocket(int roomId) async {
    print('Attempting to reconnect WebSocket for room $roomId');
    await _disconnectFromRoomWebSocket(roomId);
    await Future.delayed(Duration(seconds: 5));
    if (_activeRoom?.roomId == roomId) {
      await _connectToRoomWebSocket(roomId);
    }
  }

  Future<List<Room>> searchRooms(String query) async {
    try {
      print('Searching rooms with query: "$query"');
      final rooms = await _repository.searchRooms(query);
      print('Found ${rooms.length} rooms matching query');

      // Her oda için aktif katılımcıları al
      for (var room in rooms) {
        final participants =
            await _repository.getActiveParticipants(room.roomId);
        room = room.copyWith(
          currentParticipants: participants.length,
          participants: participants,
        );
      }

      return rooms;
    } catch (e) {
      _error = e.toString();
      print('Error searching rooms: $_error');
      notifyListeners();
      rethrow;
    }
  }

  // Odanın güncel bilgilerini al
  Future<Room> refreshRoomDetails(int roomId) async {
    try {
      print('Refreshing room details for room $roomId');
      final room = await _repository.getRoomDetails(roomId);

      // Kullanıcı odaları arasında varsa güncelle
      final index = _userRooms.indexWhere((r) => r.roomId == roomId);
      if (index != -1) {
        _userRooms[index] = room;

        // Aktif oda ise, onu da güncelle
        if (_activeRoom?.roomId == roomId) {
          _activeRoom = room;
        }

        notifyListeners();
      }

      return room;
    } catch (e) {
      print('Error refreshing room details for room $roomId: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Tüm WebSocket bağlantılarını ve timer'ları kapat
    for (var roomId in _roomWebSockets.keys) {
      _disconnectFromRoomWebSocket(roomId);
    }
    super.dispose();
  }
}
