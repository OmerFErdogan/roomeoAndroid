// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  final SharedPreferences _prefs;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  AuthProvider(this._prefs);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.login(email, password);
      _token = response['token'];
      _currentUser = User.fromJson(response['user']);
      
      if (_token != null) {
        await _prefs.setString('token', _token!);
      }
      notifyListeners();
    } catch (e) {
      print("Login error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (response.token != null) {
        _token = response.token;
        await _prefs.setString('token', _token!);
      }
      _currentUser = response.user;
      notifyListeners();
    } catch (e) {
      print("Register error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _prefs.remove('token');
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}
