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
  }

  // Repository ve veri yapıları
  final MessageRepository _repository = MessageRepository();
  final Map<int, List<Message>> _roomMessages = {};
  final Map<int, bool> _isLoadingMap = {};
  String? _error;

  // Her oda için event subscription'ları saklayacağız
  final Map<int, StreamSubscription<MessageEvent>> _subscriptions = {};

  // Her oda için son yenileme zamanını takip et
  final Map<int, DateTime> _lastRefreshTimes = {};

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
      final messages = await _repository.getRoomMessages(roomId, limit: 100);

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

      // Son yenileme zamanını kaydet
      _lastRefreshTimes[roomId] = DateTime.now();
    } catch (e) {
      _error = e.toString();
      print('Error loading messages: $_error');
    } finally {
      _isLoadingMap[roomId] = false;
      notifyListeners();
    }
  }

  // Tüm eski mesajlar dahil yükleme
  Future<void> loadAllMessages(int roomId) async {
    if (_isLoadingMap[roomId] == true) return;

    _isLoadingMap[roomId] = true;
    _error = null;
    notifyListeners();

    try {
      // İlk yükleme - son 100 mesaj
      final initialMessages =
          await _repository.getRoomMessages(roomId, limit: 100);

      // Mesajları sırala
      initialMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Eğer 100'den az mesaj varsa, tüm mesajlar yüklenmiş demektir
      if (initialMessages.length < 100) {
        _roomMessages[roomId] = initialMessages;
        print(
            'Loaded all messages (${initialMessages.length}) for room $roomId');
      } else {
        // Eğer daha fazla mesaj varsa, tarihe göre daha eski mesajları yükle
        // En eski mesajı bul
        final oldestMessage = initialMessages
            .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);

        // Daha eski mesajları yükle
        final olderMessages = await _repository.getRoomMessages(roomId,
            limit: 300, // Eski mesajlardan daha fazla al
            before: oldestMessage.createdAt);

        // Tüm mesajları birleştir
        final allMessages = [...initialMessages, ...olderMessages];

        // Mesajları sırala
        allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _roomMessages[roomId] = allMessages;
        print(
            'Loaded ${allMessages.length} messages in total for room $roomId');
      }

      // Event Bus üzerinden mesajları dinlemeye başla
      _listenForMessages(roomId);

      // Son yenileme zamanını kaydet
      _lastRefreshTimes[roomId] = DateTime.now();
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

  // Yerel mesajı hemen ekle - ANINDA gösterim için
  void addLocalMessage(int roomId, Message localMessage) {
    if (!_roomMessages.containsKey(roomId)) {
      _roomMessages[roomId] = [];
    }

    // Önce yerel mesajı ekle
    _roomMessages[roomId] = [..._roomMessages[roomId]!, localMessage];
    _roomMessages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Event Bus'a da yayınla
    final eventBus = MessageEventBus();
    eventBus.publish(MessageEvent(
      type: MessageEventType.sent,
      roomId: roomId,
      message: localMessage,
    ));

    // UI'ı ANINDA güncelle
    notifyListeners();

    // Kısa bir gecikme ile tekrar notifyListeners() çağır - UI güncellemesini garanti et
    Future.delayed(Duration(milliseconds: 50), () {
      notifyListeners();
    });

    print('LOCAL message instantly added to UI: ${localMessage.content}');
  }

  // Arka planda mesaj gönderme - UI güncellemeyi beklemeden
  Future<void> sendMessageBackground(
    int roomId,
    String content, {
    int? userId,
    String? username,
    Message? localMessage,
  }) async {
    try {
      print('Background: Sending message to room $roomId: $content');

      // API'ye gönder - 5 saniyeye kadar bekle ama UI bloklanmasın
      final serverMessage = await _repository
          .sendMessage(roomId, content)
          .timeout(Duration(seconds: 5), onTimeout: () {
        print('Background: API call timed out after 5 seconds');
        throw TimeoutException('Message sending timed out');
      });

      print(
          'Background: Message successfully sent to server with ID: ${serverMessage.messageId}');

      // Yerel mesajı sunucu mesajı ile değiştir (eğer varsa)
      if (localMessage != null) {
        _replaceTemporaryMessage(roomId, localMessage, serverMessage);
        print('Background: Replaced local message with server message');
      }

      // Sunucudan gelen mesajı event bus'a yayınla
      final eventBus = MessageEventBus();
      eventBus.publish(MessageEvent(
        type:
            MessageEventType.received, // received kullanıyoruz, serverdan geldi
        roomId: roomId,
        message: serverMessage,
      ));
    } catch (e) {
      print('Background error sending message: $e');
      // Sunucuya mesaj gönderilemediyse bile UI'da yerel mesaj halen görünür olur
    }
  }

  // Yeni mesaj gönderme - UI'da ANINDA görünme ve arka planda gönderme
  Future<void> sendMessage(int roomId, String content,
      {int? userId, String? username}) async {
    if (content.trim().isEmpty) return;

    try {
      print('MessageProvider: Sending message to room $roomId: $content');

      // Yerel mesaj nesnesi oluştur
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

      // HEMEN yerel mesajı ekle - anında UI güncellemesi
      addLocalMessage(roomId, localMessage);
      print('MessageProvider: Added local message to UI: $content');

      // ARKA PLANDA göndermeyi başlat - UI'ı bloklamaz
      sendMessageBackground(roomId, content,
          userId: userId, username: username, localMessage: localMessage);
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

      // Kritik: Her mesaj eklendiğinde UI'ı güncelle
      notifyListeners();

      // Kısa bir gecikme ile tekrar UI güncellemesi yap - bazı UI sorunlarını çözer
      Future.delayed(Duration(milliseconds: 50), () {
        notifyListeners();
      });
    }
  }

  // Geçici mesajı sunucu yanıtıyla değiştir
  void _replaceTemporaryMessage(
      int roomId, Message tempMessage, Message serverMessage) {
    if (!_roomMessages.containsKey(roomId)) return;

    print(
        'Replacing temporary message ID=${tempMessage.messageId} with server message ID=${serverMessage.messageId}');

    final updatedMessages = _roomMessages[roomId]!.map((m) {
      if (m.messageId == tempMessage.messageId &&
          m.content == tempMessage.content) {
        print('Found match, replacing local message with server message');
        return serverMessage;
      }
      return m;
    }).toList();

    _roomMessages[roomId] = updatedMessages;

    // UI'ı güncelle
    notifyListeners();

    // Kısa bir gecikme ile tekrar UI güncellemesi yap
    Future.delayed(Duration(milliseconds: 50), () {
      notifyListeners();
    });
  }

  // WebSocket üzerinden yeni mesaj ekle
  void addWebSocketMessage(int roomId, Message message) {
    print(
        'MessageProvider: Processing WebSocket message for room $roomId: ${message.content}');

    // EventBus üzerinden yayınla
    final eventBus = MessageEventBus();
    eventBus.publish(MessageEvent(
      type: MessageEventType.received,
      roomId: roomId,
      message: message,
    ));

    // Ayrıca doğrudan odaya da ekle
    _addMessageToRoom(roomId, message);

    // UI'ı tekrar güncelle
    notifyListeners();

    print('MessageProvider: WebSocket message processed');
  }

  // Tüm mesajları yenile - her 2 saniyede bir çağrılabilir
  Future<void> refreshMessages(int roomId) async {
    // Son yenilemeden bu yana geçen süreyi kontrol et, çok sık yenileme yapma
    final lastRefresh = _lastRefreshTimes[roomId] ??
        DateTime.now().subtract(Duration(minutes: 1));
    final timeSinceLastRefresh = DateTime.now().difference(lastRefresh);

    // En az 1 saniye geçtiyse yenile
    if (timeSinceLastRefresh.inMilliseconds < 1000) {
      //print('Too soon to refresh messages for room $roomId, skipping');
      return;
    }

    try {
      print('Refreshing messages for room $roomId');
      _lastRefreshTimes[roomId] = DateTime.now(); // Şimdi yenilediğimizi kaydet

      final messages = await _repository.getRoomMessages(roomId, limit: 50);

      if (messages.isEmpty) {
        print('No messages returned from server for room $roomId');
        return;
      }

      // Yeni mesajları ekle
      bool anyNewMessages = false;
      for (final message in messages) {
        // Mesaj halihazırda varsa atlayın
        if (_roomMessages[roomId]?.any((m) =>
                m.messageId == message.messageId &&
                message.messageId != -999 &&
                message.messageId != -1) ??
            false) {
          continue;
        }

        // Yeni mesajı ekle
        _addMessageToRoom(roomId, message);
        anyNewMessages = true;
      }

      if (anyNewMessages) {
        print('Added new messages during refresh');
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing messages: $e');
    }
  }

  // Oda mesajlarını temizle
  void clearMessages(int roomId) {
    _roomMessages.remove(roomId);
    _isLoadingMap.remove(roomId);
    _lastRefreshTimes.remove(roomId);
    _error = null;
    _subscriptions[roomId]?.cancel();
    _subscriptions.remove(roomId);
    notifyListeners();
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
