// lib/core/utils/message_event_bus.dart
import 'dart:async';
import '../../data/models/message.dart';

// Message event types
enum MessageEventType {
  received,
  sent,
  deleted,
  userJoined,
  userLeft,
  roomUpdated
}

// Message event data class
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

// Singleton Event Bus class
class MessageEventBus {
  // Singleton instance
  static final MessageEventBus _instance = MessageEventBus._internal();
  factory MessageEventBus() => _instance;
  MessageEventBus._internal();

  // Broadcast StreamController for multiple listeners
  final _eventController = StreamController<MessageEvent>.broadcast();

  // Get event stream
  Stream<MessageEvent> get eventStream => _eventController.stream;

  // Publish a new message event
  void publish(MessageEvent event) {
    if (!_eventController.isClosed) {
      print(
          'MessageEventBus: Publishing event ${event.type} for room ${event.roomId}');
      _eventController.sink.add(event);
    } else {
      print(
          'Warning: Attempted to publish event ${event.type} after event bus was closed');
    }
  }

  // Listen for events for a specific room
  Stream<MessageEvent> listenForRoom(int roomId) {
    return eventStream.where((event) => event.roomId == roomId);
  }

  // Listen for specific event types
  Stream<MessageEvent> listenForType(MessageEventType type) {
    return eventStream.where((event) => event.type == type);
  }

  // Cleanup resources
  void dispose() {
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }
}
