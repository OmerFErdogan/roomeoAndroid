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

  // lib/data/repositories/message_repository.dart içindeki sendMessage fonksiyonunu düzeltelim

  Future<Message> sendMessage(int roomId, String content) async {
    try {
      print('Sending message to room $roomId: $content');

      // YENİ: Hataları daha iyi takip etmek için request detayını yazdır
      print(
          'Request details: POST /rooms/$roomId/messages - Content: $content');

      final response = await _dio.post(
        '/rooms/$roomId/messages',
        data: {'content': content, 'message_type': 'text'},
        // YENİ: Timeout süresini uzatalım
        options: Options(
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      print('Message send response: ${response.data}');
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          // YENİ: Sunucudan dönen veriyi daha detaylı işle
          if (response.data is Map<String, dynamic>) {
            return Message.fromJson(response.data);
          } else {
            print('Response is not a Map: ${response.data.runtimeType}');
            print('Response content: ${response.data}');

            // Geçici bir mesaj döndür
            return Message(
              messageId: -1,
              roomId: roomId,
              userId: -1,
              username: 'Sistem',
              content: content,
              messageType: 'text',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        } catch (parseError) {
          print('Error parsing message response: $parseError');
          print('Response data: ${response.data}');

          // Manuel olarak mesaj oluştur
          return Message(
            messageId: -1,
            roomId: roomId,
            userId: -1,
            username: 'Sistem',
            content: content,
            messageType: 'text',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }

      throw NetworkException(
          'Failed to send message: Unexpected status code ${response.statusCode}');
    } on DioException catch (e) {
      print('Dio error sending message: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Request that caused the error: ${e.requestOptions.uri}');
      print('Request method: ${e.requestOptions.method}');
      print('Request headers: ${e.requestOptions.headers}');
      print('Request data: ${e.requestOptions.data}');

      if (e.response?.statusCode == 401) {
        throw AuthException('Unauthorized access');
      } else if (e.response?.statusCode == 403) {
        throw ForbiddenException('Not active in room or banned');
      } else if (e.response?.statusCode == 404) {
        throw NotFoundException('Room not found');
      }
      throw NetworkException(
        e.response?.data?['error'] ?? 'Failed to send message: ${e.message}',
      );
    } catch (e) {
      print('Unexpected error sending message: $e');
      throw NetworkException('Failed to send message: $e');
    }
  }

  Future<Message> sendMessageWithClientId(
      int roomId, String content, String clientId) async {
    try {
      print('Sending message to room $roomId with clientId: $clientId');

      // Use the Dio instance to send the message with clientId
      final response = await _dio.post(
        '/rooms/$roomId/messages',
        data: {
          'content': content,
          'message_type': 'text',
          'client_id': clientId, // Send clientId to server
        },
        options: Options(
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      print('Message send response: ${response.data}');
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          // Process server response
          if (response.data is Map<String, dynamic>) {
            // Add clientId to response data if it's not already there
            Map<String, dynamic> messageData = response.data;
            messageData['client_id'] = clientId;

            return Message.fromJson(messageData);
          } else {
            print('Response is not a Map: ${response.data.runtimeType}');

            // Return fallback message with clientId
            return Message(
              messageId: -1,
              roomId: roomId,
              userId: -1,
              username: 'Sistem',
              content: content,
              messageType: 'text',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              clientId: clientId,
            );
          }
        } catch (parseError) {
          print('Error parsing message response: $parseError');

          // Return fallback message with clientId
          return Message(
            messageId: -1,
            roomId: roomId,
            userId: -1,
            username: 'Sistem',
            content: content,
            messageType: 'text',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            clientId: clientId,
          );
        }
      }

      throw NetworkException('Failed to send message with client ID');
    } catch (e) {
      print('Error sending message with clientId: $e');
      rethrow;
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
