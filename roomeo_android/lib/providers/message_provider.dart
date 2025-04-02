// lib/providers/message_provider.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/models/message.dart';
import '../data/repositories/message_repository.dart';
import '../core/utils/message_event_bus.dart';

class MessageProvider extends ChangeNotifier {
  // Singleton pattern
  static final MessageProvider _instance = MessageProvider._internal();
  factory MessageProvider() => _instance;

  // Private constructor
  MessageProvider._internal() {
    print('MessageProvider initialized as singleton');
  }

  // Repository and data structures
  final MessageRepository _repository = MessageRepository();
  final Map<int, List<Message>> _roomMessages = {};
  final Map<int, bool> _isLoadingMap = {};
  String? _error;

  // Event subscriptions by room
  final Map<int, StreamSubscription<MessageEvent>> _subscriptions = {};

  // Last refresh times by room
  final Map<int, DateTime> _lastRefreshTimes = {};

  // Get filtered messages for a room - exclude empty and join/leave messages
  List<Message> getMessagesForRoom(int roomId) {
    final allMessages = _roomMessages[roomId] ?? [];

    // Filter out empty messages or join/leave system messages
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

  // Get sorted messages for a room
  List<Message> getSortedMessagesForRoom(int roomId) {
    final messages = getMessagesForRoom(roomId);
    final sorted = List<Message>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // Load messages for a room and start listening
  Future<void> loadMessages(int roomId) async {
    if (_isLoadingMap[roomId] == true) return;

    _isLoadingMap[roomId] = true;
    _error = null;
    notifyListeners();

    try {
      final messages = await _repository.getRoomMessages(roomId, limit: 100);

      // Sort messages by creation time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Filter out join/leave messages
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

      // Start listening for messages via EventBus
      _listenForMessages(roomId);

      // Record last refresh time
      _lastRefreshTimes[roomId] = DateTime.now();
    } catch (e) {
      _error = e.toString();
      print('Error loading messages: $_error');
    } finally {
      _isLoadingMap[roomId] = false;
      notifyListeners();
    }
  }

  // Load all messages including historical ones
  Future<void> loadAllMessages(int roomId) async {
    if (_isLoadingMap[roomId] == true) return;

    _isLoadingMap[roomId] = true;
    _error = null;
    notifyListeners();

    try {
      // Initial load - last 100 messages
      final initialMessages =
          await _repository.getRoomMessages(roomId, limit: 100);

      // Sort messages
      initialMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // If fewer than 100 messages, we've got all of them
      if (initialMessages.length < 100) {
        _roomMessages[roomId] = initialMessages;
        print(
            'Loaded all messages (${initialMessages.length}) for room $roomId');
      } else {
        // If more messages exist, load older ones too
        // Find the oldest message
        final oldestMessage = initialMessages
            .reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);

        // Load older messages
        final olderMessages = await _repository.getRoomMessages(roomId,
            limit: 300, // Get more older messages
            before: oldestMessage.createdAt);

        // Combine all messages
        final allMessages = [...initialMessages, ...olderMessages];

        // Sort by timestamp
        allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _roomMessages[roomId] = allMessages;
        print(
            'Loaded ${allMessages.length} messages in total for room $roomId');
      }

      // Start listening for messages via EventBus
      _listenForMessages(roomId);

      // Record last refresh time
      _lastRefreshTimes[roomId] = DateTime.now();
    } catch (e) {
      _error = e.toString();
      print('Error loading messages: $_error');
    } finally {
      _isLoadingMap[roomId] = false;
      notifyListeners();
    }
  }

  // Start listening for messages
  void _listenForMessages(int roomId) {
    // Cancel previous subscription if it exists
    _subscriptions[roomId]?.cancel();

    // Create new subscription
    final eventBus = MessageEventBus();
    _subscriptions[roomId] = eventBus.listenForRoom(roomId).listen((event) {
      print('MessageProvider: Received event ${event.type} for room $roomId');

      // Process event by type
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
          // Handle message deletion here
          break;
        // Ignore other events for now
        case MessageEventType.userJoined:
        case MessageEventType.userLeft:
        case MessageEventType.roomUpdated:
          break;
      }
    });

    print('Started listening for messages in room $roomId');
  }

  // Add a local message immediately - for INSTANT display
  void addLocalMessage(int roomId, Message localMessage) {
    if (!_roomMessages.containsKey(roomId)) {
      _roomMessages[roomId] = [];
    }

    // Add local message first
    _roomMessages[roomId] = [..._roomMessages[roomId]!, localMessage];
    _roomMessages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Publish to EventBus as well
    final eventBus = MessageEventBus();
    eventBus.publish(MessageEvent(
      type: MessageEventType.sent,
      roomId: roomId,
      message: localMessage,
    ));

    // Update UI IMMEDIATELY
    notifyListeners();

    // Call notifyListeners again after a short delay to ensure UI updates
    Future.delayed(Duration(milliseconds: 50), () {
      notifyListeners();
    });

    print('LOCAL message instantly added to UI: ${localMessage.content}');
  }

  // Send message in background - don't wait for UI updates
  Future<void> sendMessageBackground(
    int roomId,
    String content, {
    int? userId,
    String? username,
    Message? localMessage,
    String? clientId,
  }) async {
    try {
      print('Background: Sending message to room $roomId: $content');

      // Send to API - wait up to 2 seconds but don't block UI
      final serverMessage = await _repository
          .sendMessage(roomId, content)
          .timeout(Duration(seconds: 2), onTimeout: () {
        print('Background: API call timed out after 2 seconds');
        throw TimeoutException('Message sending timed out');
      });

      print(
          'Background: Message successfully sent to server with ID: ${serverMessage.messageId}');

      // Add clientId to server message if it was provided
      Message messageToAdd = serverMessage;
      if (clientId != null) {
        messageToAdd = Message(
          messageId: serverMessage.messageId,
          roomId: serverMessage.roomId,
          userId: serverMessage.userId,
          username: serverMessage.username,
          content: serverMessage.content,
          messageType: serverMessage.messageType,
          createdAt: serverMessage.createdAt,
          updatedAt: serverMessage.updatedAt,
          isDeleted: serverMessage.isDeleted,
          clientId: clientId,
        );
      }

      // Replace local message with server message if needed
      if (localMessage != null) {
        _replaceTemporaryMessage(roomId, localMessage, messageToAdd);
        print('Background: Replaced local message with server message');
      } else {
        // If no local message provided, add the server message directly
        _addMessageToRoom(roomId, messageToAdd);
      }

      // Publish server message to EventBus
      final eventBus = MessageEventBus();
      eventBus.publish(MessageEvent(
        type:
            MessageEventType.received, // Using received since it's from server
        roomId: roomId,
        message: messageToAdd,
      ));
    } catch (e) {
      print('Background error sending message: $e');
      // Local message will still be visible in UI even if server send fails
    }
  }

  // NEW: Send message with client ID for proper tracking
  // Update in message_provider.dart
  Future<void> sendMessageWithClientId(
    int roomId,
    String content,
    String clientId, {
    int? userId,
    String? username,
  }) async {
    if (content.trim().isEmpty) return;

    try {
      print('MessageProvider: Sending message with clientId: $clientId');
      
      // Create local message with client ID
      final localMessage = Message(
        messageId: -999,
        roomId: roomId,
        userId: userId ?? -1,
        username: username ?? 'Ben',
        content: content, // Saf içerik, client ID eklenmedi
        messageType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        clientId: clientId, // Include clientId
      );

      // IMMEDIATELY add local message for instant UI update
      addLocalMessage(roomId, localMessage);
      
      // Send in background with clientId for tracking
      sendMessageBackground(
        roomId, 
        content, // Saf içerik, client ID eklenmedi
        userId: userId,
        username: username,
        localMessage: localMessage,
        clientId: clientId
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send a message - IMMEDIATELY visible in UI, backward compatibility method
  Future<void> sendMessage(int roomId, String content,
      {int? userId, String? username}) async {
    if (content.trim().isEmpty) return;

    try {
      print('MessageProvider: Sending message to room $roomId: $content (legacy method)');

      // Generate a client ID
      final clientId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Use the clientId-based implementation
      return sendMessageWithClientId(
        roomId,
        content,
        clientId,
        userId: userId,
        username: username,
      );
    } catch (e) {
      _error = e.toString();
      print('Error in sendMessage flow: $_error');
      notifyListeners();
    }
  }

  // Add message to room
  void _addMessageToRoom(int roomId, Message message) {
    // Filter join/leave messages
    if (message.messageType == 'system' &&
        (message.content.contains('joined the room') ||
            message.content.contains('left the room'))) {
      print('Filtering system message: ${message.content}');
      return;
    }

    if (!_roomMessages.containsKey(roomId)) {
      _roomMessages[roomId] = [];
    }

    // Duplicate check: don't add if a non-temporary message with same ID exists
    final isDuplicate = _roomMessages[roomId]!.any((m) =>
        m.messageId == message.messageId &&
        m.messageId != -999 &&
        m.messageId != -1);

    // Also check for client ID match to prevent duplicates
    final isClientIdDuplicate = message.clientId != null &&
        _roomMessages[roomId]!
            .any((m) => m.clientId != null && m.clientId == message.clientId);

    if (!isDuplicate && !isClientIdDuplicate) {
      _roomMessages[roomId] = [..._roomMessages[roomId]!, message];
      _roomMessages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      print('Added message to room $roomId: ${message.content}');

      // Critical: Update UI for each added message
      notifyListeners();

      // Call notifyListeners again after a short delay to fix UI issues
      Future.delayed(Duration(milliseconds: 50), () {
        notifyListeners();
      });
    }
  }

  // Replace temporary message with server response
  void _replaceTemporaryMessage(
      int roomId, Message tempMessage, Message serverMessage) {
    if (!_roomMessages.containsKey(roomId)) return;

    print(
        'Replacing temporary message ID=${tempMessage.messageId} with server message ID=${serverMessage.messageId}');

    // First try to match by client ID if available
    if (tempMessage.clientId != null && serverMessage.clientId != null) {
      final updatedMessages = _roomMessages[roomId]!.map((m) {
        if (m.clientId == tempMessage.clientId) {
          print(
              'Found match by clientId, replacing local message with server message');
          return serverMessage;
        }
        return m;
      }).toList();

      _roomMessages[roomId] = updatedMessages;
      
      // Update UI IMMEDIATELY
      notifyListeners();
      
      return; // Exit early if we found and replaced by clientId
    }

    // Fall back to content matching if no client ID
    final updatedMessages = _roomMessages[roomId]!.map((m) {
      if (m.messageId == tempMessage.messageId &&
          m.content == tempMessage.content) {
        print(
            'Found match by content, replacing local message with server message');
        return serverMessage;
      }
      return m;
    }).toList();

    _roomMessages[roomId] = updatedMessages;

    // Update UI IMMEDIATELY
    notifyListeners();
  }

  // Add WebSocket message - backward compatibility method
  void addWebSocketMessage(int roomId, Message message) {
    print(
        'MessageProvider: Processing WebSocket message for room $roomId: ${message.content}');

    // Publish via EventBus
    final eventBus = MessageEventBus();
    eventBus.publish(MessageEvent(
      type: MessageEventType.received,
      roomId: roomId,
      message: message,
    ));

    // Also add directly to room
    _addMessageToRoom(roomId, message);

    // Update UI immediately
    notifyListeners();

    print('MessageProvider: WebSocket message processed');
  }

  // Refresh messages - can be called every few seconds
  Future<void> refreshMessages(int roomId) async {
    // Check time since last refresh, don't refresh too frequently
    final lastRefresh = _lastRefreshTimes[roomId] ??
        DateTime.now().subtract(Duration(minutes: 1));
    final timeSinceLastRefresh = DateTime.now().difference(lastRefresh);

    // Refresh only if at least 500ms has passed (previously 1000ms)
    if (timeSinceLastRefresh.inMilliseconds < 500) {
      return;
    }

    try {
      print('Refreshing messages for room $roomId');
      _lastRefreshTimes[roomId] = DateTime.now(); // Record refresh time

      final messages = await _repository.getRoomMessages(roomId, limit: 50);

      if (messages.isEmpty) {
        print('No messages returned from server for room $roomId');
        return;
      }

      // Add new messages
      bool anyNewMessages = false;
      for (final message in messages) {
        // Skip if message already exists by ID
        bool exists = _roomMessages[roomId]?.any((m) => 
            (m.messageId == message.messageId && 
             message.messageId != -999 && 
             message.messageId != -1)) ?? false;
             
        // Skip if message exists by clientId
        bool existsByClientId = false;
        if (message.clientId != null) {
          existsByClientId = _roomMessages[roomId]?.any((m) => 
              m.clientId != null && 
              m.clientId == message.clientId) ?? false;
        }
        
        if (exists || existsByClientId) {
          continue;
        }

        // Add new message
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

  // Clear messages for a room
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
