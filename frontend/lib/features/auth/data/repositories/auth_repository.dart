// lib/features/auth/data/repositories/auth_repository.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/dto/auth_dto.dart';

class AuthRepository {
  final ApiService apiService;

  AuthRepository({required this.apiService});

  Future<LoginResponse> login(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);
      final response = await apiService.login(request);

      // Сохраняем токен
      await apiService.saveToken(response.token);

      return response;
    } catch (e) {
      debugPrint('AuthRepository login error: $e');
      rethrow;
    }
  }

  Future<RegisterResponse> register(
      String username, String password, String name) async {
    try {
      final request =
          RegisterRequest(username: username, password: password, name: name);
      final response = await apiService.register(request);

      return response;
    } catch (e) {
      debugPrint('AuthRepository register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await apiService.clearToken();
  }
}
