// lib/providers/room_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:roome_android/core/utils/message_event_bus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Timer için

import '../core/error/exceptions.dart';
import '../data/models/room.dart';
import '../data/models/room_participant.dart';
import '../data/models/message.dart';
import '../data/repositories/room_repository.dart';
import '../providers/message_provider.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _repository = RoomRepository();

  List<Room> _userRooms = [];
  Map<int, List<RoomParticipant>> _roomParticipants = {};
  Map<int, WebSocketChannel?> _roomWebSockets = {};
  Map<int, bool> _roomConnectionStatus = {}; // Her oda için bağlantı durumu
  Map<int, Timer?> _pingTimers = {}; // Her oda için ping timer
  Map<int, Timer?> _refreshTimers = {}; // Her oda için yenileme timer'ı
  Map<int, int> _reconnectAttempts = {}; // Yeniden bağlanma denemesi sayısı
  Map<int, DateTime> _lastMessageTime = {}; // Son mesaj zaman damgası
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
      // YENİ: Hem aktif hem de çıkmış kullanıcıları alıyoruz
      final participants = await _repository.getActiveParticipants(roomId);
      _roomParticipants[roomId] = participants;
      print('Fetched ${participants.length} participants for room $roomId');

      // Aktif katılımcıların sayısını kontrol et
      final activeCount = participants.where((p) => p.isActive).length;
      print(
          'Active participants: $activeCount, Inactive: ${participants.length - activeCount}');

      // Oda bilgisini güncelle
      final index = _userRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        _userRooms[index] = _userRooms[index].copyWith(
          currentParticipants: activeCount, // Sadece aktif olanları say
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
      final activeParticipants = participants.where((p) => p.isActive).length;
      print(
          'Room $roomId has $activeParticipants active participants after entering');

      // Oda bilgilerini güncelle
      final index = _userRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        _activeRoom = _userRooms[index].copyWith(
          currentParticipants: activeParticipants,
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

    // Yeniden bağlanma denemesi sayısını sıfırla veya başlat
    _reconnectAttempts[roomId] = 0;

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

      // Ping timer'ı başlat - bağlantıyı aktif tutmak için
      _pingTimers[roomId]?.cancel(); // Önceki timer varsa iptal et
      _pingTimers[roomId] = Timer.periodic(Duration(seconds: 20), (_) {
        // 30 saniyeden 20 saniyeye düşürdük
        if (_roomConnectionStatus[roomId] == true) {
          print('Sending ping to room $roomId');
          try {
            channel.sink.add(jsonEncode({'type': 'ping'}));
          } catch (e) {
            print('Error sending ping to room $roomId: $e');
            _roomConnectionStatus[roomId] = false;
            _reconnectWebSocket(roomId);
          }
        }
      });

      // YENİ: Periyodik katılımcı güncellemesi için timer ekle
      _refreshTimers[roomId]?.cancel();
      _refreshTimers[roomId] = Timer.periodic(Duration(seconds: 10), (_) {
        if (_roomConnectionStatus[roomId] == true) {
          fetchRoomParticipants(roomId);
        }
      });

      // Bağlantı açıldığında katılımcı listesini güncelle
      fetchRoomParticipants(roomId);

      // Stream dinleme
      _listenToWebSocketStream(roomId, channel);

      print('WebSocket connection established for room $roomId');
    } catch (e) {
      print('WebSocket connection error for room $roomId: $e');
      _roomConnectionStatus[roomId] = false;
      _reconnectWebSocket(roomId);
    }
    notifyListeners();
  }

  //  Stream dinleme mantığını ayrı bir metoda çıkardık
  void _listenToWebSocketStream(int roomId, WebSocketChannel channel) {
    channel.stream.listen(
      (data) {
        print('WebSocket data received for room $roomId: $data');

        // Son mesaj zaman damgasını güncelle
        _lastMessageTime[roomId] = DateTime.now();

        if (data is String) {
          // Pong yanıtı gelirse bağlantı durumunu güncelle
          if (data.contains('pong')) {
            _roomConnectionStatus[roomId] = true;
            print('Received pong from room $roomId');
            return;
          }

          // Katılımcı değişiklikleri
          if (data.contains('joined the room')) {
            print('User joined room $roomId: $data');

            // Kullanıcı adını çıkar
            final username = data.split(' ')[0];
            print('Username that joined: $username');

            // Katılımcı listesini hemen güncelle
            fetchRoomParticipants(roomId);

            // EventBus'a katılma olayını yayınla
            final eventBus = MessageEventBus();
            eventBus.publish(MessageEvent(
              type: MessageEventType.userJoined,
              roomId: roomId,
              data: data,
            ));
            return;
          }

          if (data.contains('left the room')) {
            print('User left room $roomId: $data');

            // Kullanıcı adını çıkar
            final username = data.split(' ')[0];
            print('Username that left: $username');

            // Önemli: Kullanıcı çıktığında, katılımcı durumlarının güncellenmesi için biraz bekle
            Future.delayed(Duration(milliseconds: 500), () {
              // Zorla güncelleme yap
              fetchRoomParticipants(roomId).then((_) {
                // UI'ı yenile
                notifyListeners();
              });
            });

            // Ayrılma olayını yayınla
            final eventBus = MessageEventBus();
            eventBus.publish(MessageEvent(
              type: MessageEventType.userLeft,
              roomId: roomId,
              data: data,
            ));
            return;
          }

          // JSON mesajı decode et ve işle
          try {
            // JSON mesajı olup olmadığını kontrol et
            if (data.trim().startsWith('{') && data.trim().endsWith('}')) {
              final message = jsonDecode(data);

              // Mesaj JSON'sa, mesaj olayını işle
              _handleWebSocketMessage(roomId, message);

              // YENİ: Mesaj içeriği varsa, doğrudan EventBus'a da yayınla
              // Bu şekilde mesajın hızlı bir şekilde diğer kullanıcılara ulaşmasını sağlıyoruz
              if (message is Map<String, dynamic> &&
                  message['content'] != null) {
                try {
                  final messageObj = Message.fromJson(message);
                  final eventBus = MessageEventBus();

                  // Aynı mesajı farklı bir tür olarak yayınla (yedek olarak)
                  eventBus.publish(MessageEvent(
                    type: MessageEventType.received,
                    roomId: roomId,
                    message: messageObj,
                  ));

                  print(
                      'WebSocket message directly published to EventBus: ${messageObj.content}');
                } catch (e) {
                  print('Error converting message for direct publishing: $e');
                }
              }
            } else if (data.contains('message')) {
              // Basit mesaj içeriği kontrolü
              print('Possible message detected in non-JSON format: $data');
              // Burada basit string mesajları da işleyebilirsiniz
            }
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
      cancelOnError: false, // Hata olsa bile dinlemeye devam et
    );
  }

  Future<void> _disconnectFromRoomWebSocket(int roomId) async {
    print('Disconnecting WebSocket for room $roomId');
    _pingTimers[roomId]?.cancel();
    _pingTimers.remove(roomId);
    _refreshTimers[roomId]?.cancel();
    _refreshTimers.remove(roomId);
    _reconnectAttempts.remove(roomId);

    final ws = _roomWebSockets[roomId];
    if (ws != null) {
      try {
        await ws.sink.close();
      } catch (e) {
        print('Error closing WebSocket for room $roomId: $e');
      }
      _roomWebSockets.remove(roomId);
    }
    _roomConnectionStatus[roomId] = false;
    notifyListeners();
  }

  void _handleWebSocketMessage(int roomId, dynamic data) {
    print('WebSocket data received for room $roomId: $data');
    final eventBus = MessageEventBus();

    if (data is Map<String, dynamic>) {
      if (data['type'] == 'participants_update') {
        print('Participants update received for room $roomId');
        // Katılımcı listesi güncellemesi
        fetchRoomParticipants(roomId);

        eventBus.publish(MessageEvent(
          type: MessageEventType.roomUpdated,
          roomId: roomId,
          data: data,
        ));
      } else {
        try {
          // Message nesnesine dönüştür
          final message = Message.fromJson(data);

          // Join/Leave mesajlarını filtreleme
          if (message.messageType == 'system' &&
              (message.content.contains('joined the room') ||
                  message.content.contains('left the room'))) {
            print('System message filtered: ${message.content}');
            return;
          }

          // Diğer tüm mesajları yayınla
          print('Publishing normal message event: ${message.content}');
          eventBus.publish(MessageEvent(
            type: MessageEventType.received,
            roomId: roomId,
            message: message,
          ));
        } catch (e) {
          print('Error processing message data: $e');
          print('Raw data: $data');
        }
      }
    }
  }

  // Oda katılımcı sayısını günceller
  Future<void> _updateRoomParticipantCount(int roomId) async {
    try {
      print('Updating participant count for room $roomId');
      final participants = await _repository.getActiveParticipants(roomId);
      final activeParticipants = participants.where((p) => p.isActive).length;

      // Odayı kullanıcının odaları arasında bul
      final index = _userRooms.indexWhere((room) => room.roomId == roomId);
      if (index != -1) {
        // Oda bulundu, katılımcı sayısını güncelle
        _userRooms[index] = _userRooms[index].copyWith(
          currentParticipants: activeParticipants,
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
    // Yeniden bağlanma deneme sayısını artır
    final attempts = (_reconnectAttempts[roomId] ?? 0) + 1;
    _reconnectAttempts[roomId] = attempts;

    // Maksimum deneme sayısını kontrol et (5 deneme)
    if (attempts > 5) {
      print(
          'Maximum reconnection attempts reached for room $roomId. Giving up.');
      return;
    }

    // Üstel geri çekilme ile bekleme süresi
    final delay = Duration(seconds: attempts * 2);
    print(
        'Attempting to reconnect WebSocket for room $roomId (Attempt $attempts) after $delay');

    await _disconnectFromRoomWebSocket(roomId);
    await Future.delayed(delay);

    // Eğer bu aktif oda ise veya 30 dakikadan az zaman geçmişse yeniden bağlan
    final lastMessageTime =
        _lastMessageTime[roomId] ?? DateTime.now().subtract(Duration(days: 1));
    final timeElapsed = DateTime.now().difference(lastMessageTime);

    if (_activeRoom?.roomId == roomId || timeElapsed.inMinutes < 30) {
      try {
        await _connectToRoomWebSocket(roomId);
        if (_roomConnectionStatus[roomId] == true) {
          // Bağlantı başarılı oldu, deneme sayısını sıfırla
          _reconnectAttempts[roomId] = 0;
          print('Successfully reconnected to room $roomId');
        }
      } catch (e) {
        print('Failed to reconnect to room $roomId: $e');
      }
    } else {
      print(
          'Not reconnecting to inactive room $roomId (Last activity: ${timeElapsed.inMinutes} minutes ago)');
    }
  }

  // Oda arama
  Future<List<Room>> searchRooms(String query) async {
    try {
      print('Searching rooms with query: "$query"');
      final rooms = await _repository.searchRooms(query);
      print('Found ${rooms.length} rooms matching query');

      // Her oda için aktif katılımcıları al
      for (var room in rooms) {
        final participants =
            await _repository.getActiveParticipants(room.roomId);
        final activeParticipants = participants.where((p) => p.isActive).length;
        room = room.copyWith(
          currentParticipants: activeParticipants,
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

  // WebSocket bağlantı durumunu periyodik olarak kontrol et
  void startConnectionHealthCheck() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      _roomWebSockets.keys.forEach((roomId) {
        // Son mesaj alımından beri geçen süreyi kontrol et
        final lastMessageTime = _lastMessageTime[roomId] ??
            DateTime.now().subtract(Duration(minutes: 5));
        final timeElapsed = DateTime.now().difference(lastMessageTime);

        // 3 dakikadan fazla mesaj gelmemişse ve bağlantı açık görünüyorsa, ping gönder
        if (timeElapsed.inMinutes > 3 &&
            (_roomConnectionStatus[roomId] ?? false)) {
          print(
              'No messages received for room $roomId in ${timeElapsed.inMinutes} minutes. Sending health check ping.');
          try {
            _roomWebSockets[roomId]?.sink.add(jsonEncode({'type': 'ping'}));
          } catch (e) {
            print('Error during health check for room $roomId: $e');
            _roomConnectionStatus[roomId] = false;
            _reconnectWebSocket(roomId);
          }
        }
      });
    });
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
