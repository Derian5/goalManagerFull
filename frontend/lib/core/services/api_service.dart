// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dto/auth_dto.dart';
import '../models/dto/week_dto.dart';
import '../models/dto/global_goal_dto.dart';

class ApiService {
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  // =============== АВТОРИЗАЦИЯ ===============
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
      headers: ApiConfig.headers(null),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Неверный email или пароль');
    } else {
      throw Exception(_errorMessage(response, 'Ошибка входа'));
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
      headers: ApiConfig.headers(null),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return RegisterResponse.fromJson(json.decode(response.body));
    } else if (response.statusCode == 400 || response.statusCode == 422) {
      throw Exception(_errorMessage(response, 'Ошибка регистрации'));
    } else if (response.statusCode == 409) {
      throw Exception('Пользователь с таким логином уже существует');
    } else {
      throw Exception(_errorMessage(response, 'Ошибка сервера'));
    }
  }

  // =============== НЕДЕЛИ ===============
  Future<List<WeekDto>> getWeeks() async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weeks}'),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Некорректный формат списка недель: ${response.body}');
      }
      final List<dynamic> data = decoded;
      return data.map((week) => WeekDto.fromJson(week)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Ошибка загрузки недель: ${response.statusCode}');
    }
  }

  Future<WeekDto> getWeek(String weekId) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weeks}/$weekId'),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      return WeekDto.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Ошибка загрузки недели: ${response.statusCode}');
    }
  }

  Future<WeekDto> createWeek(WeekDto week) async {
    final token = await _getToken();
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weeks}'),
      headers: ApiConfig.headers(token),
      body: json.encode(week.toJson()),
    );

    if (response.statusCode == 201) {
      return WeekDto.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Ошибка создания недели: ${response.statusCode}');
    }
  }

  Future<void> deleteWeek(String weekId) async {
    final token = await _getToken();
    final response = await client.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weeks}/$weekId'),
      headers: ApiConfig.headers(token),
    );
    if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    }
    if (response.statusCode != 204) {
      throw Exception('Ошибка удаления недели: ${response.statusCode}');
    }
  }

  // lib/core/services/api_service.dart
  Future<WeekDto> updateWeekHours(
      String weekId, UpdateHoursRequest request) async {
    final token = await _getToken();

    // 1. Отправляем запрос на обновление часов
    final updateResponse = await client.patch(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weeks}/$weekId/hours'),
      headers: ApiConfig.headers(token),
      body: json.encode(request.toJson()),
    );

    if (updateResponse.statusCode == 401) {
      throw Exception('Требуется авторизация');
    }
    if (updateResponse.statusCode != 200) {
      // Если сервер вернул ошибку — бросаем исключение
      final error = json.decode(updateResponse.body);
      throw Exception(error['error'] ?? 'Ошибка обновления часов');
    }

    // 2. После успешного обновления загружаем обновлённую неделю
    final getResponse = await client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.weeks}/$weekId'),
      headers: ApiConfig.headers(token),
    );

    if (getResponse.statusCode == 200) {
      return WeekDto.fromJson(json.decode(getResponse.body));
    } else if (getResponse.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Не удалось загрузить обновлённую неделю');
    }
  }

  // =============== ГЛОБАЛЬНЫЕ ЦЕЛИ ===============
  Future<GlobalGoalsResponse> getGlobalGoals({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    final token = await _getToken();

    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.globalGoals}').replace(
        queryParameters: queryParams,
      ),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      return GlobalGoalsResponse.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Ошибка загрузки целей: ${response.statusCode}');
    }
  }

  Future<GlobalGoalDto> getGlobalGoal(String goalId) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.globalGoals}/$goalId'),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      return GlobalGoalDto.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Ошибка загрузки цели: ${response.statusCode}');
    }
  }

  Future<GlobalGoalDto> createGlobalGoal(
      CreateGlobalGoalRequest request) async {
    final token = await _getToken();
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.globalGoals}'),
      headers: ApiConfig.headers(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return GlobalGoalDto.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Ошибка создания цели: ${response.statusCode}');
    }
  }

  Future<GlobalGoalDto> updateGlobalGoal(
    String goalId,
    CreateGlobalGoalRequest request,
  ) async {
    final token = await _getToken();
    final response = await client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.globalGoals}/$goalId'),
      headers: ApiConfig.headers(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return GlobalGoalDto.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception('Ошибка обновления цели: ${response.statusCode}');
    }
  }

  Future<void> deleteGlobalGoal(String goalId) async {
    final token = await _getToken();
    final response = await client.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.globalGoals}/$goalId'),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    }
    if (response.statusCode != 204) {
      throw Exception('Ошибка удаления цели: ${response.statusCode}');
    }
  }

  Future<List<GlobalGoalDto>> getGlobalGoalsForWeek(String weekId) async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.globalGoals}/week/$weekId'),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((goal) => GlobalGoalDto.fromJson(goal)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    } else {
      throw Exception(
          'Ошибка загрузки целей для недели: ${response.statusCode}');
    }
  }

  // =============== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===============
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = json.decode(response.body);
      final detail =
          decoded['detail'] ?? decoded['message'] ?? decoded['error'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return first['msg'];
        }
      }
    } catch (_) {}

    return '$fallback: ${response.statusCode}';
  }
}
