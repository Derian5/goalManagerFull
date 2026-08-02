// lib/core/config/api_config.dart
class ApiConfig {
  // Базовый URL вашего сервера
  static const String baseUrl = 'http://goalmanager.work.gd/api'; //TODO заменить на реальный URL

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String weeks = '/weeks';
  static const String globalGoals = '/goals';


  // Заголовки
  static Map<String, String> headers(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}