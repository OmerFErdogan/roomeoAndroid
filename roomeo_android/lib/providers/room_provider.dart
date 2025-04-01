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

      // Her oda için aktif katılımcıları al
      for (var room in _userRooms) {
        await fetchRoomParticipants(room.roomId);
      }

      _activeRoom = _userRooms.firstWhereOrNull(
        (room) => room.hasActiveParticipants,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoomParticipants(int roomId) async {
    try {
      final participants = await _repository.getActiveParticipants(roomId);
      _roomParticipants[roomId] = participants;

      // Oda bilgisini güncelle
      final index = _userRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        _userRooms[index] = _userRooms[index].copyWith(
          currentParticipants: participants.length,
          participants: participants,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error fetching participants: $e');
    }
  }

  Future<void> enterRoom(int roomId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.enterRoom(roomId);
      await fetchRoomParticipants(roomId);

      _activeRoom =
          _userRooms.firstWhereOrNull((room) => room.roomId == roomId);

      // WebSocket bağlantısını başlat
      await _connectToRoomWebSocket(roomId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> exitRoom(int roomId) async {
    try {
      await _repository.exitRoom(roomId);
      _activeRoom = null;

      // WebSocket bağlantısını kapat
      await _disconnectFromRoomWebSocket(roomId);

      // Katılımcı listesini güncelle
      await fetchRoomParticipants(roomId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> joinRoom(int roomId, {String? accessCode}) async {
    try {
      await _repository.joinRoom(roomId, accessCode: accessCode);
      await fetchUserRooms();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveRoom(int roomId) async {
    try {
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
      final room = await _repository.createRoom(
        name: name,
        description: description,
        roomType: roomType,
        isPrivate: isPrivate,
      );

      _userRooms = [..._userRooms, room];
      notifyListeners();
      return room;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // WebSocket Operations
  Future<void> _connectToRoomWebSocket(int roomId) async {
    if (_roomWebSockets[roomId] != null) {
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

      final channel = WebSocketChannel.connect(wsUrl);
      _roomWebSockets[roomId] = channel;
      _roomConnectionStatus[roomId] = true;

      // Ping timer'ı başlat
      _pingTimers[roomId] = Timer.periodic(Duration(seconds: 30), (_) {
        if (_roomConnectionStatus[roomId] == true) {
          channel.sink.add(jsonEncode({'type': 'ping'}));
        }
      });

      channel.stream.listen(
        (data) {
          if (data is String) {
            if (data.contains('pong')) {
              // Pong yanıtını işle
              _roomConnectionStatus[roomId] = true;
              return;
            }

            // System mesajları için özel işleme
            if (data.contains('joined the room') ||
                data.contains('left the room')) {
              // Sadece bağlantı aktifse ve kullanıcı odadaysa işle
              if (_roomConnectionStatus[roomId] == true &&
                  _activeRoom?.roomId == roomId) {
                fetchRoomParticipants(roomId);
              }
              return;
            }

            try {
              final message = jsonDecode(data);
              _handleWebSocketMessage(roomId, message);
            } catch (e) {
              print('Error processing WebSocket message: $e');
            }
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _roomConnectionStatus[roomId] = false;
          _reconnectWebSocket(roomId);
        },
        onDone: () {
          print('WebSocket connection closed');
          _roomConnectionStatus[roomId] = false;
          _reconnectWebSocket(roomId);
        },
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      _roomConnectionStatus[roomId] = false;
    }
    notifyListeners();
  }

  Future<void> _disconnectFromRoomWebSocket(int roomId) async {
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
    if (message['type'] == 'participants_update') {
      // Katılımcı listesi güncellemesi
      fetchRoomParticipants(roomId);
    }
  }

  Future<void> _reconnectWebSocket(int roomId) async {
    await _disconnectFromRoomWebSocket(roomId);
    await Future.delayed(Duration(seconds: 5));
    if (_activeRoom?.roomId == roomId) {
      await _connectToRoomWebSocket(roomId);
    }
  }

  Future<List<Room>> searchRooms(String query) async {
    try {
      final rooms = await _repository.searchRooms(query);

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
      notifyListeners();
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
