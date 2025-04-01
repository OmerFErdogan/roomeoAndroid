// lib/data/repositories/auth_repository.dart
import 'package:dio/dio.dart';

import '../../core/error/exceptions.dart';
import '../../core/init/network_manager.dart';
import '../models/user.dart';

class AuthRepository {
  final _dio = NetworkManager.instance.dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid email or password');
      }
      throw AppException('Login failed: ${e.message}');
    }
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? profileImage,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'profile_image': profileImage,
        },
      );
      
      return AuthResponse(
        token: response.data['token'],
        user: User.fromJson(response.data['user']),
      );
    } on DioException catch (e) {
      print("Register error: ${e.message}");
      print("Error response: ${e.response?.data}");
      throw AuthException(e.response?.data?['error'] ?? 'Registration failed');
    }
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });
}
