import 'package:dio/dio.dart';
import '../models/message.dart';
import '../../core/init/network_manager.dart';
import '../../core/error/exceptions.dart';

class MessageRepository {
  final _dio = NetworkManager.instance.dio;

  Future<List<Message>> getRoomMessages(
    int roomId, {
    int? limit = 50,
    DateTime? before,
    DateTime? after,
  }) async {
    try {
      final queryParams = {
        'limit': (limit ?? 50).toString(),
        if (before != null) 'before': before.toIso8601String(),
        if (after != null) 'after': after.toIso8601String(),
      };

      final response = await _dio.get(
        '/rooms/$roomId/messages',
        queryParameters: queryParams,
      );

      // API yanıtı messages array içinde geliyor
      if (response.data != null && response.data['messages'] != null) {
        final List<dynamic> messages = response.data['messages'];
        return messages.map((json) => Message.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized access');
      } else if (e.response?.statusCode == 403) {
        throw ForbiddenException('Not active in room or banned');
      } else if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      throw NetworkException(
        e.response?.data?['error'] ?? 'Failed to get messages',
      );
    }
  }

  Future<Message> sendMessage(int roomId, String content) async {
    try {
      final response = await _dio.post(
        '/rooms/$roomId/messages',
        data: {
          'content': content,
          'message_type': 'text' // Şimdilik sadece text mesajları
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Message.fromJson(response.data);
      }

      throw NetworkException('Failed to send message');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized access');
      } else if (e.response?.statusCode == 403) {
        throw ForbiddenException('Not active in room or banned');
      } else if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      throw NetworkException(
        e.response?.data?['error'] ?? 'Failed to send message',
      );
    }
  }

  Future<void> deleteMessage(int roomId, int messageId) async {
    try {
      final response = await _dio.delete(
        '/rooms/$roomId/messages/$messageId',
      );

      if (response.statusCode != 200) {
        throw NetworkException('Failed to delete message');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized access');
      } else if (e.response?.statusCode == 403) {
        throw ForbiddenException('Not authorized to delete message');
      } else if (e.response?.statusCode == 404) {
        throw NotFoundException('Message not found');
      }
      throw NetworkException(
        e.response?.data?['error'] ?? 'Failed to delete message',
      );
    }
  }
}
