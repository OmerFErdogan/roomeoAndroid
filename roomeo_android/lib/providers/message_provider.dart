// lib/providers/message_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/message.dart';
import '../data/repositories/message_repository.dart';
import '../core/utils/message_event_bus.dart';

class MessageProvider extends ChangeNotifier {
  // Singleton pattern - tek bir instance oluşturalım
  static final MessageProvider _instance = MessageProvider._internal();
  factory MessageProvider() => _instance;

  // Özel constructor
  MessageProvider._internal() {
    print('MessageProvider initialized as singleton');
    // Burada başlangıç ayarlarını yapabilirsiniz
  }

  // Repository ve veri yapıları
  final MessageRepository _repository = MessageRepository();
  final Map<int, List<Message>> _roomMessages = {};
  final Map<int, bool> _isLoadingMap = {};
  String? _error;

  // Her oda için event subscription'ları saklayacağız
  final Map<int, StreamSubscription<MessageEvent>> _subscriptions = {};

  // Filtreli mesajlar getiren metod - joined/left mesajlarını hariç
  List<Message> getMessagesForRoom(int roomId) {
    final allMessages = _roomMessages[roomId] ?? [];

    // İçeriği boş mesajları veya joined/left mesajlarını filtrele
    return allMessages
        .where((message) =>
            message.content.trim().isNotEmpty &&
            !(message.messageType == 'system' &&
                (message.content.contains('joined the room') ||
                    message.content.contains('left the room'))))
        .toList();
  }

  bool isLoadingForRoom(int roomId) => _isLoadingMap[roomId] ?? false;
  String? get error => _error;

  // Sıralı mesajları almak için metod
  List<Message> getSortedMessagesForRoom(int roomId) {
    final messages = getMessagesForRoom(roomId);
    final sorted = List<Message>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // Oda mesajlarını yükle ve dinlemeye başla
  Future<void> loadMessages(int roomId) async {
    if (_isLoadingMap[roomId] == true) return;

    _isLoadingMap[roomId] = true;
    _error = null;
    notifyListeners();

    try {
      final messages = await _repository.getRoomMessages(roomId);

      // Mesajları sırala
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Mesajları filtrele - join/leave mesajlarını çıkar
      final filteredMessages = messages
          .where((message) =>
              message.content.trim().isNotEmpty &&
              !(message.messageType == 'system' &&
                  (message.content.contains('joined the room') ||
                      message.content.contains('left the room'))))
          .toList();

      _roomMessages[roomId] = filteredMessages;
      print(
          'Loaded ${filteredMessages.length} messages for room $roomId (filtered from ${messages.length})');

      // Event Bus üzerinden mesajları dinlemeye başla
      _listenForMessages(roomId);
    } catch (e) {
      _error = e.toString();
      print('Error loading messages: $_error');
    } finally {
      _isLoadingMap[roomId] = false;
      notifyListeners();
    }
  }

  // Mesaj dinlemeyi başlat
  void _listenForMessages(int roomId) {
    // Önceki subscription varsa iptal et
    _subscriptions[roomId]?.cancel();

    // Yeni bir subscription oluştur
    final eventBus = MessageEventBus();
    _subscriptions[roomId] = eventBus.listenForRoom(roomId).listen((event) {
      print('MessageProvider: Received event ${event.type} for room $roomId');

      // Mesaj türüne göre işlem yap
      switch (event.type) {
        case MessageEventType.received:
          if (event.message != null) {
            _addMessageToRoom(roomId, event.message!);
          }
          break;
        case MessageEventType.sent:
          if (event.message != null) {
            _addMessageToRoom(roomId, event.message!);
          }
          break;
        case MessageEventType.deleted:
          // Mesaj silme işlemi burada yapılacak
          break;
        // Diğer eventleri şimdilik görmezden gel
        case MessageEventType.userJoined:
        case MessageEventType.userLeft:
        case MessageEventType.roomUpdated:
          break;
      }
    });

    print('Started listening for messages in room $roomId');
  }

  // Yeni mesaj gönderme - bu metod artık AuthProvider kullanmıyor
  Future<void> sendMessage(int roomId, String content,
      {int? userId, String? username}) async {
    if (content.trim().isEmpty) return;

    try {
      print('MessageProvider: Sending message to room $roomId: $content');

      // Mesaj oluştur - artık dışarıdan userId ve username alabiliyoruz
      final localMessage = Message(
        messageId: -999, // Geçici ID
        roomId: roomId,
        userId: userId ?? -1,
        username: username ?? 'Ben', // Varsayılan değer
        content: content,
        messageType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Önce yerel mesajı ekle ve UI'ı güncelle
      if (!_roomMessages.containsKey(roomId)) {
        _roomMessages[roomId] = [];
      }
      _roomMessages[roomId] = [..._roomMessages[roomId]!, localMessage];
      _roomMessages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
      print('MessageProvider: Added local message to UI: $content');

      // NOT: Yerel mesaj UI'ya eklendiği için event bus'a tekrar publish etmiyoruz.

      // API'ye gönder
      try {
        final serverMessage = await _repository.sendMessage(roomId, content);

        // Yerel mesajı sunucu mesajı ile değiştir
        _replaceTemporaryMessage(roomId, localMessage, serverMessage);
        print('MessageProvider: Replaced local message with server message');
      } catch (apiError) {
        print('API error when sending message: $apiError');
        // API hatası olsa bile UI güncellemesi yapıldığı için mesaj görünecek
      }
    } catch (e) {
      _error = e.toString();
      print('Error in sendMessage flow: $_error');
      notifyListeners();
    }
  }

  // Mesajı odaya ekle
  void _addMessageToRoom(int roomId, Message message) {
    // Join/leave mesajlarını filtrele
    if (message.messageType == 'system' &&
        (message.content.contains('joined the room') ||
            message.content.contains('left the room'))) {
      print('Filtering system message: ${message.content}');
      return;
    }

    if (!_roomMessages.containsKey(roomId)) {
      _roomMessages[roomId] = [];
    }

    // Duplicate kontrolü: aynı mesajID'ye sahip (geçici olmayan) mesaj varsa ekleme
    final isDuplicate = _roomMessages[roomId]!.any((m) =>
        m.messageId == message.messageId &&
        m.messageId != -999 &&
        m.messageId != -1);

    if (!isDuplicate) {
      _roomMessages[roomId] = [..._roomMessages[roomId]!, message];
      _roomMessages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      print('Added message to room $roomId: ${message.content}');
      notifyListeners();
    }
  }

  // Geçici mesajı sunucu yanıtıyla değiştir
  void _replaceTemporaryMessage(
      int roomId, Message tempMessage, Message serverMessage) {
    if (!_roomMessages.containsKey(roomId)) return;

    final updatedMessages = _roomMessages[roomId]!.map((m) {
      if (m.messageId == tempMessage.messageId &&
          m.content == tempMessage.content) {
        return serverMessage;
      }
      return m;
    }).toList();

    _roomMessages[roomId] = updatedMessages;
    notifyListeners();
  }

  // WebSocket üzerinden mesaj ekle - artık event bus aracılığıyla alınacak
  void addWebSocketMessage(int roomId, Message message) {
    final eventBus = MessageEventBus();
    eventBus.publish(MessageEvent(
      type: MessageEventType.received,
      roomId: roomId,
      message: message,
    ));
  }

  // Oda mesajlarını temizle
  void clearMessages(int roomId) {
    _roomMessages.remove(roomId);
    _isLoadingMap.remove(roomId);
    _error = null;
    _subscriptions[roomId]?.cancel();
    _subscriptions.remove(roomId);
    notifyListeners();
  }

  // Tüm mesajları yenile (manuel kullanım için)
  Future<void> refreshMessages(int roomId) async {
    try {
      final messages = await _repository.getRoomMessages(roomId);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final filteredMessages = messages
          .where((message) =>
              message.content.trim().isNotEmpty &&
              !(message.messageType == 'system' &&
                  (message.content.contains('joined the room') ||
                      message.content.contains('left the room'))))
          .toList();
      _roomMessages[roomId] = filteredMessages;
      print('Refreshed ${filteredMessages.length} messages for room $roomId');
      notifyListeners();
    } catch (e) {
      print('Error refreshing messages: $e');
    }
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
