// lib/core/utils/message_event_bus.dart
import 'dart:async';
import '../../data/models/message.dart';

// Mesaj olayı türleri
enum MessageEventType {
  received,
  sent,
  deleted,
  userJoined,
  userLeft,
  roomUpdated
}

// Mesaj olayı veri sınıfı
class MessageEvent {
  final MessageEventType type;
  final int roomId;
  final Message? message;
  final dynamic data;

  MessageEvent({
    required this.type,
    required this.roomId,
    this.message,
    this.data,
  });
}

// Singleton Event Bus sınıfı
class MessageEventBus {
  // Singleton instance
  static final MessageEventBus _instance = MessageEventBus._internal();
  factory MessageEventBus() => _instance;
  MessageEventBus._internal();

  // Broadcast özellikli StreamController, birden fazla dinleyicinin olması için
  final _eventController = StreamController<MessageEvent>.broadcast();

  // Event Stream'ini al
  Stream<MessageEvent> get eventStream => _eventController.stream;

  // Yeni bir mesaj olayı yayınla
  void publish(MessageEvent event) {
    if (!_eventController.isClosed) {
      print(
          'MessageEventBus: Publishing event ${event.type} for room ${event.roomId}');
      _eventController.sink.add(event);
    }
  }

  // Belirli bir oda için mesaj eventi dinle
  Stream<MessageEvent> listenForRoom(int roomId) {
    return eventStream.where((event) => event.roomId == roomId);
  }

  // Belirli tipteki eventleri dinle
  Stream<MessageEvent> listenForType(MessageEventType type) {
    return eventStream.where((event) => event.type == type);
  }

  // Kaynakları temizle
  void dispose() {
    _eventController.close();
  }
}
