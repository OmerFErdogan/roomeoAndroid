// lib/providers/message_provider.dart
import 'package:flutter/material.dart';
import '../data/models/message.dart';
import '../data/repositories/message_repository.dart';

class MessageProvider extends ChangeNotifier {
  final MessageRepository _repository = MessageRepository();

  final Map<int, List<Message>> _roomMessages = {};
  final Map<int, bool> _isLoadingMap = {};
  String? _error;

  List<Message> getMessagesForRoom(int roomId) => _roomMessages[roomId] ?? [];
  bool isLoadingForRoom(int roomId) => _isLoadingMap[roomId] ?? false;
  String? get error => _error;

  // Sıralı mesajları almak için yeni metod
  List<Message> getSortedMessagesForRoom(int roomId) {
    final messages = getMessagesForRoom(roomId);
    final sorted = List<Message>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  Future<void> loadMessages(int roomId) async {
    if (_isLoadingMap[roomId] == true) return;

    _isLoadingMap[roomId] = true;
    _error = null;
    notifyListeners();

    try {
      final messages = await _repository.getRoomMessages(roomId);
      // Mesajları sıralama
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _roomMessages[roomId] = messages;
    } catch (e) {
      _error = e.toString();
      print('Error loading messages: $_error');
    } finally {
      _isLoadingMap[roomId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int roomId, String content) async {
    try {
      final message = await _repository.sendMessage(roomId, content);
      if (!_roomMessages.containsKey(roomId)) {
        _roomMessages[roomId] = [];
      }

      // Mesajı ekle ve sırala
      _roomMessages[roomId] = [..._roomMessages[roomId]!, message];
      _roomMessages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error sending message: $_error');
      notifyListeners();
      rethrow;
    }
  }

  void addWebSocketMessage(int roomId, Message message) {
    if (!_roomMessages.containsKey(roomId)) {
      _roomMessages[roomId] = [];
    }

    // Mesajın zaten listeye eklenip eklenmediğini kontrol et (duplikeyi önle)
    final hasMessage = _roomMessages[roomId]!.any((m) =>
            m.messageId == message.messageId &&
            m.messageId != -1 // System mesajlarında ID -1 olabilir
        );

    // Mesaj zaten eklenmişse ekleme
    if (!hasMessage) {
      _roomMessages[roomId] = [..._roomMessages[roomId]!, message];
      // Her ekleme sonrası sırala
      _roomMessages[roomId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    }
  }

  void clearMessages(int roomId) {
    _roomMessages.remove(roomId);
    _isLoadingMap.remove(roomId);
    _error = null;
    notifyListeners();
  }
}
